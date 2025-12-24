#!/bin/bash

# Install DMS using Helm
# Note: Ensure your mail domain DNS is configured before running this script
#
# Optional: Configure outbound SMTP relay (recommended when TCP/25 egress is blocked)
#   export SMTP_RELAY_HOST='[smtp.sendgrid.net]:587'
#   export SMTP_RELAY_USER='apikey'
#   export SMTP_RELAY_PASSWORD='<SENDGRID_API_KEY>'
#
# Update the hostname in ./k3s/helm/values/dms.values.yaml with your mail server domain

helm repo add docker-mailserver https://docker-mailserver.github.io/docker-mailserver-helm
helm repo update

# Create namespace first 
# The `--dry-run=client -o yaml | kubectl apply -f -` pattern is idempotent: 
# it prints the namespace manifest and applies it, so it won’t error if the namespace already exists.
kubectl create namespace mail --dry-run=client -o yaml | kubectl apply -f -

# Create Certificate resource for cert-manager
cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: mail-livingroom-cloud
  namespace: mail
spec:
  secretName: mail-livingroom-cloud-tls
  issuerRef:
    name: cloudflare-letsencrypt-production
    kind: ClusterIssuer
  privateKey:
    rotationPolicy: Always
    algorithm: RSA
    size: 2048
  dnsNames:
  - mail.livingroom.cloud
---
EOF

# Install docker-mailserver
#
# Optional relay overlay values file:
# - Preferred: create `./k3s/helm/values/docker-mailserver.relay.values.yaml` (and reference k8s secrets there)
# - Fallback: set SMTP_RELAY_HOST/USER/PASSWORD and we'll generate an overlay values file at runtime
RELAY_VALUES_ARGS=()
if [[ -f ./k3s/helm/values/docker-mailserver.relay.values.yaml ]]; then
  RELAY_VALUES_ARGS+=(--values ./k3s/helm/values/docker-mailserver.relay.values.yaml)
elif [[ -n "${SMTP_RELAY_HOST:-}" || -n "${SMTP_RELAY_USER:-}" || -n "${SMTP_RELAY_PASSWORD:-}" ]]; then
  if [[ -z "${SMTP_RELAY_HOST:-}" || -z "${SMTP_RELAY_USER:-}" || -z "${SMTP_RELAY_PASSWORD:-}" ]]; then
    echo "ERROR: To use SMTP relay you must set SMTP_RELAY_HOST, SMTP_RELAY_USER, and SMTP_RELAY_PASSWORD" >&2
    exit 1
  fi

  RELAY_VALUES_ARGS+=(--values <(cat <<EOF
deployment:
  env:
    DEFAULT_RELAY_HOST: "${SMTP_RELAY_HOST}"
    RELAY_USER: "${SMTP_RELAY_USER}"
    RELAY_PASSWORD: "${SMTP_RELAY_PASSWORD}"
EOF
))
fi

helm install docker-mailserver docker-mailserver/docker-mailserver \
  --namespace mail \
  --create-namespace \
  --values ./k3s/helm/values/docker-mailserver.values.yaml \
  "${RELAY_VALUES_ARGS[@]}"

# Initial Setup
# ------------
#  You have two minutes to setup a first email account after the initial deployment.
kubectl exec -n mail deploy/docker-mailserver -- setup email add admin@mail.livingroom.cloud admin

# Generate DKIM key
kubectl exec -n mail deploy/docker-mailserver -- setup config dkim

# Capture DKIM TXT value (flattened) into env var for reuse
DKIM_TXT=$(kubectl exec -n mail deploy/docker-mailserver -- sh -c "cat /tmp/docker-mailserver/opendkim/keys/mail.livingroom.cloud/mail.txt" \
  | awk -F'"' 'BEGIN{ORS="";}{for(i=2;i<NF;i+=2)printf "%s",$i}END{print "";}')
echo "DKIM TXT (raw): ${DKIM_TXT}"

# Chunk DKIM into <=255-char segments for DNS (Cloudflare/TXT limit)
chunk_dkim() {
  local s="$1" out=""
  while [ -n "$s" ]; do
    out="${out}\"${s:0:255}\", "
    s="${s:255}"
  done
  # strip trailing comma+space
  printf '%s\n' "${out%, }"
}
DKIM_CHUNKED=$(chunk_dkim "${DKIM_TXT}")
echo "DKIM TXT (chunked): ${DKIM_CHUNKED}"

# Update DNS records with DKIM key (replace to avoid duplicates)
# Note: DKIM_CHUNKED is already a comma-separated, quoted list.
cat <<EOF | kubectl replace --force -f -
---
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: livingroom-cloud-mail-records
  namespace: external-dns
spec:
  endpoints:
  - dnsName: mail.livingroom.cloud
    recordType: A
    recordTTL: 300
    targets: [ "174.44.105.210" ]
  - dnsName: mail.livingroom.cloud
    recordType: MX
    recordTTL: 3600
    targets: [ "10 mail.livingroom.cloud." ]
  - dnsName: mail.livingroom.cloud
    recordType: TXT
    recordTTL: 300
    targets: [ "v=spf1 a:mail.livingroom.cloud ip4:174.44.105.210 -all" ]
  - dnsName: _dmarc.mail.livingroom.cloud
    recordType: TXT
    recordTTL: 300
    targets: [ "v=DMARC1; p=none; rua=mailto:dmarc-reports@livingroom.cloud; pct=100" ]
  - dnsName: mail._domainkey.mail.livingroom.cloud
    recordType: TXT
    recordTTL: 300
    targets: [ ${DKIM_CHUNKED} ]
---
EOF

# Show DKIM TXT record
dig TXT mail._domainkey.mail.livingroom.cloud +short

# Test the email setup
kubectl exec -n mail deploy/docker-mailserver -- swaks \
  --to seemywings@gmail.com \
  --from admin@mail.livingroom.cloud \
  --server mail.livingroom.cloud \
  --auth LOGIN \
  --auth-user admin@mail.livingroom.cloud \
  --auth-password 'admin' \
  --tls --port 587
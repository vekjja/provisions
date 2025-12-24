#!/bin/bash

# Install DMS using Helm
# Note: Ensure your mail domain DNS is configured before running this script
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
helm install docker-mailserver docker-mailserver/docker-mailserver \
  --namespace mail \
  --create-namespace \
  --values ./k3s/helm/values/docker-mailserver.values.yaml

# Initial Setup
# ------------
#  You have two minutes to setup a first email account after the initial deployment.
kubectl exec -it --namespace mail deploy/docker-mailserver -- bash
setup email add user@example.com password

# Generate DKIM key
kubectl exec -n mail deploy/docker-mailserver -- setup config dkim

# Capture DKIM TXT value (flattened) into env var for reuse
DKIM_TXT=$(kubectl exec -n mail deploy/docker-mailserver -- sh -c "cat /tmp/docker-mailserver/opendkim/keys/mail.livingroom.cloud/mail.txt" \
  | awk -F'"' 'BEGIN{ORS="";}{for(i=2;i<NF;i+=2)printf "%s",$i}END{print "";}')
echo "DKIM TXT: ${DKIM_TXT}"

# Update DNS records with DKIM key (keep all existing endpoints together)
cat <<EOF | kubectl apply -f -
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
    targets: [ "${DKIM_TXT}" ]
---
EOF

# Show DKIM TXT record
dig TXT mail._domainkey.mail.livingroom.cloud +short

# Test the email setup
kubectl exec -n mail deploy/docker-mailserver -- swaks --to seemywings@gmail.com --from admin@livingroom.cloud --server 127.0.0.1 --auth LOGIN --auth-user admin@livingroom.cloud --auth-password 'admin' --tls --port 587
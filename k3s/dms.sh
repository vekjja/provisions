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
  --values ./k3s/helm/values/dms.values.yaml

# Initial Setup
# ------------
#  You have two minutes to setup a first email account after the initial deployment.

kubectl exec -it --namespace mail deploy/docker-mailserver -- bash
setup email add user@example.com password

# Test the email setup
kubectl exec -n mail deploy/docker-mailserver -- swaks --to seemywings@gmail.com --from admin@livingroom.cloud --server 127.0.0.1 --auth LOGIN --auth-user admin@livingroom.cloud --auth-password 'admin' --tls --port 587
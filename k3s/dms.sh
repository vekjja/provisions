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

Initial Setup
------------

# If you have not yet configured your mail server you'll need to quickly open a command
# prompt inside the running container (you have two minutes) and setup a first email account.

#     kubectl exec -it --namespace mail deploy/docker-mailserver -- bash

#     setup email add user@example.com password

# This will create a file:

#     cat /tmp/docker-mailserver/postfix-accounts.cf

# Next, run the setup command to see additional options:

#     setup

# For more information please refer to this Chart's README file.

# Proxy Ports
# ------------
# You have enabled PROXY protocol support, likely because you are running on a bare metal Kubernetes cluster. 
# This means additional ports have been created that are configured for the PROXY protocol. 
# These ports are in the 10,000 range - thus IMAPs is 10993 (10000 + 993), SUBMISSION is 10587 (10000 + 587), etc.

# It is now up to you to configure incoming traffic to use these ports. 
# For more information please refer to this Chart's README file.
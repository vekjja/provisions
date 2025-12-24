#!/bin/bash

# Install ExternalDNS (official chart) for Cloudflare
# Requires environment variable CLOUDFLARE_API_TOKEN (DNS edit scope for the zone)

set -euo pipefail

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

# Namespace and secret
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -

# Create secret for Cloudflare API token
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN required}" \
  -n external-dns \
  --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade ExternalDNS (official chart)
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --values ./k3s/helm/values/external-dns.values.yaml



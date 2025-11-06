#!/bin/bash

set -e

# Helm repo setup
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL using Helm with flags
helm upgrade --install psql bitnami/postgresql \
  --namespace "your-namespace" \
  --create-namespace \
  --set primary.persistence.storageClass=local-path \
  --set primary.persistence.enabled=true \
  --set primary.persistence.size=10Gi \
  --set volumePermissions.enabled=true

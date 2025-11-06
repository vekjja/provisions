#!/bin/bash

set -e

PSQL_NAMESPACE="psql"

# Helm repo setup
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL using Helm with flags
helm upgrade --install psql bitnami/postgresql \
  --namespace ${PSQL_NAMESPACE} \
  --create-namespace \
  --set primary.persistence.storageClass=local-path \
  --set primary.persistence.enabled=true \
  --set primary.persistence.size=10Gi \
  --set volumePermissions.enabled=true

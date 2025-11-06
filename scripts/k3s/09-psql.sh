#!/bin/bash

set -e

kubectl create namespace psql || true

# Helm repo setup
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL using Helm with values file
helm upgrade --install psql bitnami/postgresql \
  --namespace psql \
  --create-namespace \
  -f ./services/psql/psql-values.yaml

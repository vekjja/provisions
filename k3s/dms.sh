#!/bin/bash

set -e

# Helm repo setup
helm repo add docker-mail-server https://docker-mailserver.github.io/helm-charts/
helm repo update

# Deploy the mail server using Helm
helm upgrade --install mail docker-mail-server \
  --namespace mail \
  --create-namespace \
  --values ./k3s/helm/values/mail.values.yaml
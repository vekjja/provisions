#!/bin/bash

set -e

# Helm repo setup
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create Grafana admin credentials secret
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-credentials
  namespace: monitoring
type: Opaque
data:
  admin-user: $(echo -n "admin" | base64)
  admin-password: $(echo -n "YOUR_PASSWORD" | base64)
EOF

# Install kube-prometheus-stack (includes Prometheus, Grafana, Alertmanager, Node Exporter, etc.)
helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack \
  --namespace "monitoring" \
  --create-namespace \
  --values ./helm/monitoring/values.yaml

# Install Loki for logging
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki for logging
# Promtail (enabled below) automatically discovers and collects logs from all pods in all namespaces
# It runs as a DaemonSet and uses Kubernetes service discovery to find pods
helm upgrade --install loki grafana/loki-stack \
  --namespace "monitoring" \
  --set loki.persistence.enabled=true \
  --set loki.persistence.storageClassName=local-path \
  --set loki.persistence.size=20Gi \
  --set promtail.enabled=true \
  --set loki.config.limits_config.retention_period=192h


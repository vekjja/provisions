#!/bin/bash

set -e

# Helm repo setup
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
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
  --values ./helm/monitoring/grafana.values.yaml

# Install Loki for logging
# Using standalone grafana/loki chart for better configuration control
helm upgrade --install loki grafana/loki \
  --namespace "monitoring" \
  --values ./helm/monitoring/loki.values.yaml

# Install Grafana Alloy for log collection
# Alloy is the recommended agent for collecting logs (replaced Promtail)
# It automatically discovers and collects logs from all pods in all namespaces
# It runs as a DaemonSet and uses Kubernetes service discovery to find pods
helm upgrade --install alloy grafana/alloy \
  --namespace "monitoring" \
  --values ./helm/monitoring/alloy.values.yaml

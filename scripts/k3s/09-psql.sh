#!/bin/bash

set -e

kubectl create namespace psql || true

# Create PV
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: psql-data
spec:
  capacity:
    storage: 108Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/ssd/pny250/PSQL
EOF

# Create matching PVC in the correct namespace
cat <<EOF | kubectl apply -n psql -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: psql-data-pvc
spec:
  volumeName: psql-data
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
EOF

# Helm repo setup
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL using Helm with values file
helm upgrade --install psql bitnami/postgresql \
    --namespace psql \
    -f ./services/psql/psql-values.yaml

#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "ssd-movies"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "ssd-movies"
  capacity:
    storage: "900Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/ssd/movies"
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "ssd-series"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "ssd-series"
  capacity:
    storage: "900Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/ssd/series"
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "ssd-series-ext"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "ssd-series-ext"
  capacity:
    storage: "1000Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/hdd/barracuda/Series"
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "plex-config"
spec:
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "plex-config"
  capacity:
    storage: "6Gi"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/ssd/pny250/Plex"
EOF
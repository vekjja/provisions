#!/bin/bash

# ███╗░░░███╗███████╗████████╗░█████╗░██╗░░░░░██╗░░░░░██████╗░
# ████╗░████║██╔════╝╚══██╔══╝██╔══██╗██║░░░░░██║░░░░░██╔══██╗
# ██╔████╔██║█████╗░░░░░██║░░░███████║██║░░░░░██║░░░░░██████╦╝
# ██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██║░░░░░██║░░░░░██╔══██╗
# ██║░╚═╝░██║███████╗░░░██║░░░██║░░██║███████╗███████╗██████╦╝
# ╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═════╝░
#
# https://metallb.universe.tf/installation/


# Install Metallb using Helm
helm repo add metallb https://metallb.github.io/metallb
helm repo update

helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace

# Create MetalLB Address Pool
cat <<EOF | kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool-10-0-1-0-24
  namespace: metallb-system
spec:
  addresses:
  - 10.0.1.0/24
---
EOF

# Create MetalLB Advertisement
cat <<EOF | kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-l2-advertisement
  namespace: metallb-system
---
EOF

# ██╗███╗░░██╗░██████╗░██████╗░███████╗░██████╗░██████╗░░░░░░███╗░░██╗░██████╗░██╗███╗░░██╗██╗░░██╗
# ██║████╗░██║██╔════╝░██╔══██╗██╔════╝██╔════╝██╔════╝░░░░░░████╗░██║██╔════╝░██║████╗░██║╚██╗██╔╝
# ██║██╔██╗██║██║░░██╗░██████╔╝█████╗░░╚█████╗░╚█████╗░█████╗██╔██╗██║██║░░██╗░██║██╔██╗██║░╚███╔╝░
# ██║██║╚████║██║░░╚██╗██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗╚════╝██║╚████║██║░░╚██╗██║██║╚████║░██╔██╗░
# ██║██║░╚███║╚██████╔╝██║░░██║███████╗██████╔╝██████╔╝░░░░░░██║░╚███║╚██████╔╝██║██║░╚███║██╔╝╚██╗
# ╚═╝╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░░░░░░░╚═╝░░╚══╝░╚═════╝░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝
# Official Kubernetes Ingress: https://kubernetes.github.io/ingress-nginx/deploy/

# Install Ingress Nginx using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --selector=app.kubernetes.io/component=controller \
  --for=condition=ready pod \
  --timeout=120s

# View LoadBalancer External IP
kubectl get service ingress-nginx-controller --namespace=ingress-nginx

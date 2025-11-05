#!/bin/bash

# ███╗░░░███╗███████╗████████╗░█████╗░██╗░░░░░██╗░░░░░██████╗░
# ████╗░████║██╔════╝╚══██╔══╝██╔══██╗██║░░░░░██║░░░░░██╔══██╗
# ██╔████╔██║█████╗░░░░░██║░░░███████║██║░░░░░██║░░░░░██████╦╝
# ██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██║░░░░░██║░░░░░██╔══██╗
# ██║░╚═╝░██║███████╗░░░██║░░░██║░░██║███████╗███████╗██████╦╝
# ╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═════╝░
#
# https://metallb.universe.tf/installation/

# Downloaded from:
# wget https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
kubectl apply -f ./yaml/metallb-native_v0.14.5.yaml

# Apply From Source:
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

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

# wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f ./yaml/ingress-nginx_v1.11.3.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Restart Ingress Controller
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

# View LoadBalancer External IP
kubectl get service ingress-nginx-controller --namespace=ingress-nginx

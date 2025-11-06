#!/bin/bash

# ░█████╗░███████╗██████╗░████████╗░░░░░░███╗░░░███╗░█████╗░███╗░░██╗░█████╗░░██████╗░███████╗██████╗░
# ██╔══██╗██╔════╝██╔══██╗╚══██╔══╝░░░░░░████╗░████║██╔══██╗████╗░██║██╔══██╗██╔════╝░██╔════╝██╔══██╗
# ██║░░╚═╝█████╗░░██████╔╝░░░██║░░░█████╗██╔████╔██║███████║██╔██╗██║███████║██║░░██╗░█████╗░░██████╔╝
# ██║░░██╗██╔══╝░░██╔══██╗░░░██║░░░╚════╝██║╚██╔╝██║██╔══██║██║╚████║██╔══██║██║░░╚██╗██╔══╝░░██╔══██╗
# ╚█████╔╝███████╗██║░░██║░░░██║░░░░░░░░░██║░╚═╝░██║██║░░██║██║░╚███║██║░░██║╚██████╔╝███████╗██║░░██║
# ░╚════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░░░░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░╚═════╝░╚══════╝╚═╝░░╚═╝

# Install Cert Manager using Helm
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  namespace: cert-manager
  name: cloudflare-api-token
type: Opaque
stringData:
  api-token: ${CLOUDFLARE_API_TOKEN}
---
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cloudflare-letsencrypt-staging
spec:
  acme:
    email: seemywings@gmail.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cloudflare-issuer-account-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
---
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cloudflare-letsencrypt-production
spec:
  acme:
    email: seemywings@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cloudflare-issuer-account-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
---
EOF

#
# ℹ️ Personal ISP Blocks Port 80 So HTTP ACME Challenge Fails
# Certificate Issuer LetsEncrypt Staging
#
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-staging
# spec:
#   acme:
#     server: https://acme-staging-v02.api.letsencrypt.org/directory
#     email: seemywings@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-staging-issuer-key
#     solvers:
#       - http01:
#           ingress:
#             class: nginx
# ---
# EOF

#
# Certificate Issuer LetsEncrypt Prod
#
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-prod
# spec:
#   acme:
#     server: https://acme-v02.api.letsencrypt.org/directory
#     email: seemywings@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-prod-issuer-key
#     solvers:
#       - http01:
#           ingress:
#             class: nginx
# ---
# EOF

#
# Example Ingress Config
#
# cat <<EOF | kubectl apply -n test -f -
# ---
# apiVersion: extensions/v1
# kind: Ingress
# metadata:
#   name: my-ingress
#   annotations:
#     kubernetes.io/ingress.class: "nginx"
#     cert-manager.io/cluster-issuer: "cloudflare-letsencrypt-staging"
# spec:
#   tls:
#   - hosts:
#     - demo.livingroom.cloud
#     secretName: "demo.livingroom.cloud-staging-tls"
#   rules:
#   - host: demo.livingroom.cloud
#     http:
#       paths:
#         - path: /
#           backend:
#             serviceName: nginx-test
#             servicePort: 80
# ---
# EOF

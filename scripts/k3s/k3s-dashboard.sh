#!/bin/bash

readonly dashboardURL=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

# Get admin-user token
k8sToken=$(kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') | grep "token:   " | awk '{print $2}')
echo $k8sToken
echo $k8sToken | pbcopy

echo
echo Kubernetes Dashboard URL: $dashboardURL
echo A valid K8S token is saved to your clipboard
kubectl proxy

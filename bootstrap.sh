#!/bin/bash

# Create the kind cluster and wait for it to come up
kind create cluster --config cluster.yml --wait 90s

kubectl apply -f metrics.yml

kubectl wait --namespace kube-system \
  --for=condition=available deployment/metrics-server \
  --timeout=90s

# Install Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Force controller onto the node with the hostPort mapping
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/nodeSelector/ingress-ready","value":"true"}]'

kubectl wait --namespace ingress-nginx \
  --for=condition=complete job/ingress-nginx-admission-patch \
  --timeout=120s

kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

helm upgrade --install todoapp ./helm-charts/todoapp --wait

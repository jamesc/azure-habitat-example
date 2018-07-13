#!/bin/sh


set -x

NAME="aks-demo"
VERSION="0.7.1"

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller
helm init --service-account tiller --wait

helm repo add habitat https://habitat-sh.github.io/habitat-operator/helm/charts/stable/
helm repo update
helm install --name ${NAME} habitat/habitat-operator --version ${VERSION}

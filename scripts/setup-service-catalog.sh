#!/bin/sh


set -x

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller
helm init --service-account tiller --wait

helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
helm repo update

helm install svc-cat/catalog \
   --name catalog --namespace catalog \
   --wait

svcat get plans


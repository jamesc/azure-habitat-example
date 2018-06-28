#!/bin/sh

set -x

PRINCIPAL_NAME="habitat-aks-osba"

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --wait

helm install svc-cat/catalog \
   --name catalog --namespace catalog \
   --wait \
   --set rbacEnable=false \
   --set apiserver.storage.etcd.persistence.enabled=true

helm repo add azure https://kubernetescharts.blob.core.windows.net/azure


OLD_ID=$(az ad sp list --spn http://${PRINCIPAL_NAME} --query "[].appId" -o tsv)
if [ ! -z ${OLD_ID} ]; then
    az ad sp delete --id ${OLD_ID}

    # And delete osba if it's installed
    helm ls osba|grep ^osba
    if [ $? -eq 0 ]; then
      helm delete --purge osba
    fi
fi
kubectl api-versions | grep servicecatalog.k8s.io/v1beta1

AZURE_SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
AZURE_CLIENT_SECRET=$(az ad sp create-for-rbac --name ${PRINCIPAL_NAME} --query "password" -o tsv)
AZURE_CLIENT_ID=$(az ad sp list --spn http://${PRINCIPAL_NAME} --query "[].appId" -o tsv)
AZURE_TENANT_ID=$(az ad sp list --spn http://${PRINCIPAL_NAME} --query "[].additionalProperties.appOwnerTenantId" -o tsv)

helm install azure/open-service-broker-azure \
  --name osba --namespace osba  \
  --wait \
  --set azure.subscriptionId=$AZURE_SUBSCRIPTION_ID \
  --set azure.tenantId=$AZURE_TENANT_ID  \
  --set azure.clientId=$AZURE_CLIENT_ID \
  --set azure.clientSecret=$AZURE_CLIENT_SECRET \
  --set modules.minStability=EXPERIMENTAL

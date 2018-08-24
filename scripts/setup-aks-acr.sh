#!/bin/sh
#
# Change these for your account
#
RESOURCE_GROUP="habitat-aks-demo"
AKS_CLUSTER_NAME="aks-demo"
ACR_NAME="habitatregistry"
LOCATION="eastus"

BLDR_PRINCIPAL_PASSWORD="ThisIsVeryStrongPassword"
#
# No Need to change these
#
BLDR_PRINCIPAL_NAME="habitat-acr-registry"
AKS_VERSION="1.11.2"
AKS_NODE_COUNT=3
AKS_NODE_SIZE="Standard_DS1_v2"
ACR_SKU="Basic"

if [ ! -z ${UNIQUE_NAME} ]; then
    UNIQUE_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
    RESOURCE_GROUP="${RESOURCE_GROUP}-${UNIQUE_ID}"
    AKS_CLUSTER_NAME="aks-demo"
    ACR_NAME="${ACR_NAME}${UNIQUE_ID}"
    BLDR_PRINCIPAL_NAME="${BLDR_PRINCIPAL_NAME}-${UNIQUE_ID}"
fi

#
# Setup AKS
#
az group create --name $RESOURCE_GROUP --location ${LOCATION} --tags "owner=${USER}"
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count $AKS_NODE_COUNT \
    --node-vm-size ${AKS_NODE_SIZE} \
    --no-ssh-key \
    --kubernetes-version ${AKS_VERSION} \
    --tags "owner=${USER}"

kubectl config delete-cluster ${AKS_CLUSTER_NAME}
kubectl config delete-context ${AKS_CLUSTER_NAME}
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

#
# Create ACR if it doesn't exist
#
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)
if [ $? -ne 0 ]; then
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku $ACR_SKU
    ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)
fi

#
# Grant Reader access to ACR from AKS
#
CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID

# Create Service Principal for Habitat Builder
OLD_ID=$(az ad sp list --spn http://${BLDR_PRINCIPAL_NAME} --query "[].appId" -o tsv)
if [ ! -z ${OLD_ID} ]; then
    az ad sp delete --id ${OLD_ID}
fi
az ad sp create-for-rbac --scopes $ACR_ID --role Owner --password "$BLDR_PRINCIPAL_PASSWORD" --name $BLDR_PRINCIPAL_NAME
BLDR_ID=$(az ad sp list --display-name $BLDR_PRINCIPAL_NAME  --query "[].appId" --output tsv)

echo "Configuration Details for Habitat Builder:"
echo "  Server URL : ${ACR_NAME}.azurecr.io"
echo "  Service Principal ID : $BLDR_ID"
echo "  Service Principal Password : $BLDR_PRINCIPAL_PASSWORD"

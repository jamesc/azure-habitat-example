#!/bin/sh
#
# Change these for your account
#
RESOURCE_GROUP="habitat-aks-demo"
AKS_CLUSTER_NAME="aks-demo"
ACR_NAME="habitatregistry"

BLDR_PRINCIPAL_PASSWORD="ThisIsVeryStrongPassword"
#
# No Need to change these
#
BLDR_PRINCIPAL_NAME="habitat-acr-registry"
AKS_NODE_COUNT=1
ACR_SKU="Basic"

#
# Setup AKS
#
az group create --name $RESOURCE_GROUP --location eastus
az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count $AKS_NODE_COUNT --generate-ssh-keys
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

#
# Setup ACR
#
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku $ACR_SKU

#
# Grant Reader access to ACR from AKS
#
CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)
az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID

# Create Service Principal for Habitat Builder
az ad sp create-for-rbac --scopes $ACR_ID --role Owner --password "$BLDR_PRINCIPAL_PASSWORD" --name $BLDR_PRINCIPAL_NAME
BLDR_ID=$(az ad sp list --display-name $BLDR_PRINCIPAL_NAME  --query "[].appId" --output tsv)

echo "Configuration Details for Habitat Builder:"
echo "  Server URL : ${ACR_NAME}.azurecr.io"
echo "  Service Principal ID : $BLDR_ID"
echo "  Service Principal Password : $BLDR_PRINCIPAL_PASSWORD"

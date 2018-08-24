#!/bin/sh
#
# Change these for your account
#
RESOURCE_GROUP="habitat-aks-demo"
AKS_CLUSTER_NAME="aks-demo"
ACR_NAME="habitatregistry"
LOCATION="eastus"

LOG_ANALYTICS_RESOURCE_GROUP="habitat-aks-demo-workspace"
LOG_ANALYTICS_RESOURCE_NAME="habitat-aks-demo"

BLDR_PRINCIPAL_PASSWORD="ThisIsVeryStrongPassword"
#
# No Need to change these
#
BLDR_PRINCIPAL_NAME="habitat-acr-registry"
AKS_VERSION="1.11.2"
AKS_NODE_COUNT=3
AKS_NODE_SIZE="Standard_B4ms"
ACR_SKU="Basic"

if [ ! -z ${UNIQUE_NAME} ]; then
    UNIQUE_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
    RESOURCE_GROUP="${RESOURCE_GROUP}-${UNIQUE_ID}"
    AKS_CLUSTER_NAME="aks-demo"
    ACR_NAME="${ACR_NAME}${UNIQUE_ID}"
    BLDR_PRINCIPAL_NAME="${BLDR_PRINCIPAL_NAME}-${UNIQUE_ID}"
fi

# Check for existing Log Analytics workspace
LA_ID=$(az resource show --resource-group ${LOG_ANALYTICS_RESOURCE_GROUP} --name ${LOG_ANALYTICS_RESOURCE_NAME} --namespace 'Microsoft.OperationalInsights' --resource-type workspaces --query id --output tsv)
WORKSPACE_OPTION=""
if [ $? -eq 0 ]; then
  echo "Found Log Analytics workspace ${LOG_ANALYTICS_RESOURCE_NAME}.  Enabling monitoring..."
  WORKSPACE_OPTION="--enable-addons monitoring --workspace-resource-id ${LA_ID}"
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
    ${WORKSPACE_OPTION} \
    --tags "owner=${USER}"

kubectl config unset users.clusterUser_${RESOURCE_GROUP}_${AKS_CLUSTER_NAME}
kubectl config delete-cluster ${AKS_CLUSTER_NAME}
kubectl config delete-context ${AKS_CLUSTER_NAME}
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

#
# Create ACR if it doesn't exist
#
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)
if [ $? -ne 0 ]; then
    echo "Creating Azure Container Registry ${ACR_NAME}"
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku $ACR_SKU
    ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)

    # Create Service Principal for Habitat Builder to push to ACR
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
else
    echo "Using existing Azure Container Registry ${ACR_NAME}"
fi

#
# Grant Reader access to ACR from AKS
#
CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID

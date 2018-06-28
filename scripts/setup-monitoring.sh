#!/bin/sh

RESOURCE_GROUP="habitat-aks-demo"
AKS_CLUSTER_NAME="aks-demo"
WORKSPACE_NAME="habitat-aks-log-analytics"
REGION="eastus"


#
ACCOUNT_ID=$( az account show --query "id" --output tsv)
TMPFILE=$(mktemp)
cat > $TMPFILE << EOM
{   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
   "contentVersion": "1.0.0.0",
   "parameters": {
     "aksResourceId": {
       "value": "/subscriptions/${ACCOUNT_ID}/resourcegroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME}"
    },
    "aksResourceLocation": {
      "value": "East US"
    },
    "workspaceId": {
      "value": "/subscriptions/${ACCOUNT_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE_NAME}"
    },
    "workspaceRegion": {
      "value": "${REGION}"
    }
  }
}
EOM

az group deployment create \
  --resource-group ${RESOURCE_GROUP} \
  --template-file existingClusterOnboarding.json \
  --parameters ${TMPFILE}

rm ${TMPFILE}

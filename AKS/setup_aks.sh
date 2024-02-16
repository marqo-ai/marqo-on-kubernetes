#!/bin/bash

# Login to Azure (uncomment the following line if not already logged in or running in an automated script)
# az login


# Set the Azure subscription ID or name
export AZURE_SUBSCRIPTION_ID=<Your Azure Subscription ID>
az account set --subscription $AZURE_SUBSCRIPTION_ID

export APP_INSTANCE_NAME=<Your App Instance Name>

export CLUSTER=<Your Cluster Name>
# Set preferred location
export LOCATION=<Your preferred location i.e useast>

# Create a resource group if it doesn't already exist
export RESOURCE_GROUP=<Your Resource Group Name>
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
export CLUSTER=<your cluster name>
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER \
    --node-vm-size Standard_D2s_v3 \ # Equivalent to n1-standard-2 in GCP
    --node-count 1 \ # Initial node count, adjust as needed
    --location $LOCATION \
    --generate-ssh-keys

# Get credentials for kubectl
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER

# Create node pools equivalent to the ones in GCP script. Adjust the size and count as needed.
az aks nodepool add --cluster-name $CLUSTER --name vespaadmin --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 1

# The default node pool is automatically created with the cluster in Azure, so we don't delete it but you can resize or modify it as needed.

az aks nodepool add --cluster-name $CLUSTER --name configserver --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 3

az aks nodepool add --cluster-name $CLUSTER --name vespafeed --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 1

az aks nodepool add --cluster-name $CLUSTER --name vespaquery --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 1

az aks nodepool add --cluster-name $CLUSTER --name vespacontent --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 2

# For non-GPU nodes
az aks nodepool add --cluster-name $CLUSTER --name marqonodes --resource-group $RESOURCE_GROUP --node-vm-size Standard_D4s_v3 --node-count 1 

# For GPU nodes, Azure supports GPU node pools as well. You'll need to specify the proper VM size and ensure that your subscription has enough quota for GPU VMs.
# az aks nodepool add --cluster-name $CLUSTER --name marqonodes --resource-group $RESOURCE_GROUP --node-vm-size Standard_NC4as_T4_v3 --node-count 1


helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=agentpool > "${APP_INSTANCE_NAME}_manifest.yaml"

kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"

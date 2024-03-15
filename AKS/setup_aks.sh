#!/bin/bash

# Login to Azure (uncomment the following line if not already logged in or running in an automated script)
# az login
echo "Setting up AKS"
date


# Set the Azure subscription ID or name
export AZURE_SUBSCRIPTION_ID=<Your Azure Subscription ID>

export APP_INSTANCE_NAME=<Your App Instance Name>

export CLUSTER=<Your Cluster Name>
# Set preferred location
export LOCATION=<Your preferred location i.e useast>

# Create a resource group if it doesn't already exist
export RESOURCE_GROUP=<Your Resource Group Name>
# INSTALL_GPU is an environment variable that indicates whether to install GPU support
INSTALL_GPU=true

az account set --subscription $AZURE_SUBSCRIPTION_ID
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER \
    --node-vm-size Standard_D2s_v3 \
    --node-count 1 \
    --location $LOCATION \
    --generate-ssh-keys

# Get credentials for kubectl
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER

# Create vespaadmin node pools.
az aks nodepool add --cluster-name $CLUSTER --name vespaadmin --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 1
# Create vesapa configserver node pools. We need 3 nodes for configserver.
az aks nodepool add --cluster-name $CLUSTER --name configserver --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 3
# Create vespa feed node pools.
az aks nodepool add --cluster-name $CLUSTER --name vespafeed --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 1
# Create vespa query node pools.
az aks nodepool add --cluster-name $CLUSTER --name vespaquery --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 1
# Create vespa content node pools. We need 2 nodes for content.
az aks nodepool add --cluster-name $CLUSTER --name vespacontent --resource-group $RESOURCE_GROUP --node-vm-size Standard_D2s_v3 --node-count 2

# For non-GPU nodes
if [ "$INSTALL_GPU" = false ]; then
    az aks nodepool add --cluster-name $CLUSTER --name marqonodes --resource-group $RESOURCE_GROUP --node-vm-size Standard_D4s_v3 --node-count 1 
fi


# For GPU nodes, Azure supports GPU node pools as well. You'll need to specify the proper VM size and ensure that your subscription has enough quota for GPU VMs.
if [ "$INSTALL_GPU" = true ]; then
    az aks nodepool add --cluster-name $CLUSTER --name marqonodes --resource-group $RESOURCE_GROUP --node-vm-size Standard_NC4as_T4_v3 --node-count 1
    # Install the NVIDIA GPU Operator
    # for more information, see https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/microsoft-aks.html
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update
    helm install gpu-operator nvidia/gpu-operator \
        -n gpu-operator --create-namespace \
        --set operator.runtimeClass=nvidia-container-runtime
fi


helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=agentpool,gpu_enabled=$INSTALL_GPU > "${APP_INSTANCE_NAME}_manifest.yaml"

kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"

echo "Successfully set up AKS"
date

![Marqo Logo](../resources/marqo.png)

# Deploying Marqo on Azure Kubernetes Service (AKS)

This guide provides instructions on how to deploy Marqo on Azure AKS using Kubernetes and Helm. The deployment process involves creating a resource group, an AKS cluster, configuring node pools, and deploying Marqo using a Helm chart.

## Prerequisites

- An Azure account.
- Azure CLI installed and configured.
- Kubernetes command-line tool (`kubectl`) installed.
- Helm installed.

## Notes
Before executing the setup script, ensure your Azure subscription has enough capacity for the following requirements:

- vCPUs: Verify the quota for vCPUs based on the node size and count you plan to use. Default setup requires 18 vCPU of type Standard_D2s_v3.
- Persistent Disk SSD: At least 240 GB required; adjust based on your setup.
- If using GPU nodes, ensure your subscription supports the desired Azure VM sizes with GPU capabilities, recommended GPU instance is Standard_NC4as_T4_v3.

## Deployment Steps


1. **Run the Setup Script:**
   First, log in to Azure CLI (if not already logged in):

   ```bash
   az login
   ```

   Set your Azure subscription ID:

   ```bash
   export AZURE_SUBSCRIPTION_ID='<your-subscription-id>'
   az account set --subscription $AZURE_SUBSCRIPTION_ID
   ```

   Customize the following variables in the `setup.sh` script to match your Azure environment:

   - **APP_INSTANCE_NAME**: Name your application instance.
   - **CLUSTER**: Define your Kubernetes cluster name.
   - **LOCATION**: Specify your preferred Azure region such as `eastus`.
   - **RESOURCE_GROUP**: Set the name for the new or existing resource group.
   - **INSTALL_GPU:** If deploying with GPU support, set INSTALL_GPU=true otherwise false.

   Run the script:
   ```bash
   ./AKS/setup_aks.sh
   ```

   This script performs the following actions:
   - Creates a resource group (if it doesn't already exist).
   - Creates an AKS cluster with specified configurations.
   - Configures various node pools for different purposes, including optional GPU nodes.
   - Applies necessary Kubernetes configurations.

3. **Kubernetes Cluster Validation:**
   After the `setup.sh` script execution completes, it may take a few minutes for the AKS cluster and its resources to become fully operational. To verify the health of the Marqo pod in the cluster, use:
   ```bash
   kubectl get pods --all-namespaces -w
   ```
   Ensure that all pods reach the `Running` state before proceeding.

4. **Test Marqo Endpoint:**

   Retrieve the IP address of your Marqo service:
   ```
   export MARQO_CLUSTER_IP=$(kubectl get svc marqo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   ```

   Set up a Python virtual environment and test the Marqo deployment:
   ```
   python3 -m venv .venv
   source .venv/bin/activate
   pip install marqo
   python test_marqo.py
   ```

## Additional Configuration

- **GPU Nodes:** If you plan to use GPU nodes, uncomment the relevant section in the `setup.sh` script before running it. This will create a node pool with GPU capabilities.

- **Custom Configurations:** Modify the Helm chart values or the `setup.sh` script as needed for custom configurations.

## Cleanup

To delete the AKS cluster and clean up the resources, run:

```bash
az aks delete --name $CLUSTER --resource-group $RESOURCE_GROUP --yes --no-wait
```

Replace `$CLUSTER` and `$RESOURCE_GROUP` with the names you have used during setup.


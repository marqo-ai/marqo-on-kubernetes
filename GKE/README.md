![Marqo Logo](../resources/marqo.png)

# Deploying Marqo on Google Kubernetes Engine (GKE)

This guide provides instructions on how to deploy Marqo on GKE using Kubernetes and Helm. The deployment process involves creating a Kubernetes cluster, configuring node pools, and deploying Marqo using a Helm chart.

## Prerequisites

- A Google Cloud account and a project.
- Google Cloud SDK (`gcloud`) installed and configured.
- Kubernetes command-line tool (`kubectl`) installed.
- Helm installed.

## Notes
Before executing the setup.sh script, ensure your GCP quotas have capacity for the following requirements:

- vCPUs (18): Verify the quota for 18 vCPUs.
- Persistent Disk SSD: At least 240 GB required; adjust based on your setup.
- IP Addresses (8): Ensure a quota for 8 IP addresses.
- NVIDIA T4 GPU (1): Required only if using GPU.

## Deployment Steps

1. **Clone the Repository:**
   Ensure you have the Marqo on GCP repository cloned to your local machine. This repository contains the necessary Helm chart and the `setup.sh` script.

   ```bash
   git clone https://github.com/marqo-ai/marqo-on-gcp.git
   cd marqo-on-gcp
   ```

2. **Run the Setup Script:**
   First authorize the gcloud CLI:

   ```bash
   gcloud auth login
   ```
   The `setup.sh` script will set up your GCP environment, create a Kubernetes cluster, and configure the necessary node pools.

   Before running the setup.sh script, review and customize the following variables to match your GCP environment:

   - **PROJECT_ID**: Set to your GCP project ID.
   - **APP_INSTANCE_NAME**: Name your application instance.
   - **CLUSTER**: Define your Kubernetes cluster name.
   - **REGION** and **ZONE**: Specify your preferred GCP region and zone.
   - **INSTALL_GPU:** If deploying with GPU support, set INSTALL_GPU=true otherwise false.


   Run the script:
   ```bash
   ./GKE/setup_gke.sh
   ```

   This script performs the following actions:
   - Sets the GCP project.
   - Enables necessary GCP services.
   - Creates a Kubernetes cluster.
   - Configures various node pools for different purposes.
   - Applies necessary Kubernetes configurations.

3. **Kubernetes Cluster Validation:**
   Execution of the `setup.sh` script includes the following automated steps:
   - Generation of the Helm chart.
   - Deployment of the generated chart onto the Kubernetes cluster.
   Typically, it takes about 3 to 5 minutes for Marqo to become operational within the cluster. To verify the health of the Marqo pod in the cluster, use:
   ```bash
   kubectl get pods --all-namespaces -w
   ```
   Ensure that all pods reach the `Running` state before proceeding.

4. **Test Marqo endpoint:**

```
export MARQO_CLUSTER_IP=$(kubectl get svc marqo -o jsonpath='{.status.loadBalancer.ingres[0].ip}')

python3 -m venv .venv
source .venv/bin/activate
pip install marqo
python test_marqo.py
```

## Additional Configuration

- **GPU Nodes:** If you plan to use GPU nodes, uncomment the relevant section in the `setup.sh` script before running it. This will create a node pool with GPU capabilities.

- **Custom Configurations:** Modify the Helm chart values or the `setup.sh` script as needed for custom configurations.

## Cleanup

To delete the Kubernetes cluster and clean up the resources, run:

```bash
gcloud container clusters delete "$CLUSTER" --quiet
```

Replace `"$CLUSTER"` with the name of your cluster if different from the one set in the script.


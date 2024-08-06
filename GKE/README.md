![Marqo Logo](../resources/marqo.png)

# Deploying Marqo on Google Kubernetes Engine (GKE)

This guide provides instructions on how to deploy Marqo on GKE using Kubernetes and Helm. The deployment process involves creating a Kubernetes cluster, configuring node pools, and deploying Marqo using a Helm chart.

## Prerequisites

- A Google Cloud account and a project.
- Google Cloud SDK (`gcloud`) installed and configured.
- The gcloud plugin gke-gcloud-auth-plugin installed with: ```gcloud components install gke-gcloud-auth-plugin```
- Kubernetes command-line tool (`kubectl`) installed.
- Helm installed.

## Notes
Before executing the setup_gke.sh script, ensure your GCP quotas have capacity for the following requirements:

- vCPUs (18): Verify the quota for 18 vCPUs.
- Persistent Disk SSD: At least 240 GB required; adjust based on your setup.
- IP Addresses (8): Ensure a quota for 8 IP addresses.
- NVIDIA T4 GPU (1): Required only if using GPU.

## Deployment Steps

1. **Clone the Repository:**</br>
   Ensure you have the Marqo on Kubernetes repository cloned to your local machine. This repository contains the necessary Helm chart and the `setup_gke.sh` script.

   ```bash
   git clone git@github.com:marqo-ai/marqo-on-kubernetes.git
   cd marqo-on-kubernetes
   ```
   
2. **Set Envars:**</br>
   Copy GKE/vars.env.template to the same dir and name it vars.env e.g.
   ```bash
   cp ./GKE/vars.env.template ./GKE/vars.env
   ```
   Edit vars.env and set the variables with real values to match your GCP environment:
   - **PROJECT_ID**: Set to your GCP project ID.
   - **APP_INSTANCE_NAME**: Name your application instance.
   - **CLUSTER**: Define your Kubernetes cluster name.
   - **REGION** and **ZONE**: Specify your preferred GCP region and zone.
   - **INSTALL_GPU:** If deploying with GPU support, set INSTALL_GPU=true otherwise false.
   </br></br>

3. **Authorize the gcloud CLI :**
   ```bash
   gcloud auth login
   ```
   Note: It should only be necessary to do this once, but nothing will break if it's done multiple times, so if 
   you run into trouble, run it again just in case</br></br>

4. **Run the Setup Script:**</br>
   The `setup_gke.sh` script will set up your GCP environment, create a Kubernetes cluster, and configure the necessary node pools.

   Run the script:
   ```bash
   sh ./GKE/setup_gke.sh deploy
   ```

   This script performs the following actions:
   - Sets the GCP project.
   - Enables necessary GCP services.
   - Creates a Kubernetes cluster.
   - Configures various node pools for different purposes.
   - Applies necessary Kubernetes configurations.
   </br></br>
   
5. **Kubernetes Cluster Validation:**</br>
Execution of `setup_gke.sh deploy` includes the following automated steps:
   - Generation of the Helm chart.
   - Deployment of the generated chart onto the Kubernetes cluster.
   Typically, it takes about 3 to 5 minutes for Marqo to become operational within the cluster. To verify the health of the Marqo pod in the cluster, use:
   ```bash
   kubectl get pods --all-namespaces -w
   ```
   Ensure that all pods reach the `Running` state before proceeding.
   </br></br>

6. **Test Marqo endpoint:**</br>
NOTE: the following test/s presume that MARQO_CLUSTER_IP has been exported as an envar 
and contains the IP address of the marqo cluster that was deployed. 
This occurs during deployment but the envar won't survive exiting the session the cluster was deployed in.
MARQO_CLUSTER_IP is therefore also written to `out/vars.env` 
so if necessary you can re-export it to the environment with
```bash
  set -a
  source out/vars.env
  set +a
```
for python, you can use the library dotenv, either dotenv_values to return all the values as a dict, or dotenv_load 
to export to the environment and then read them in using os.environ["key_name"]

To run a simple test
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r test/requirements.txt
python test_marqo.py
```

## Additional Configuration
- **Custom Configurations:** Modify the Helm chart values or the `setup_gke.sh` script as needed for custom configurations.

## Cleanup
To delete the Kubernetes cluster and clean up the resources, run:
```bash
sh ./GKE/setup.sh destroy
```

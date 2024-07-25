![Marqo Logo](../resources/marqo.png)

# Deploying Marqo on Amazon Elastic Kubernetes Service (EKS)

This guide outlines the steps to deploy Marqo on Amazon EKS using Kubernetes and Helm. The deployment involves creating an EKS cluster, configuring node groups for different purposes, and deploying Marqo using a Helm chart.

## Prerequisites

- An AWS account.
- AWS CLI installed and configured with appropriate credentials.
- Kubernetes command-line tool (`kubectl`) installed.
- Helm installed.
- eksctl installed.

## Notes
Ensure your AWS account has enough resources for the following requirements before executing the setup script:

- **vCPUs:** Check the limit for the required number of vCPUs based on the node size and count you plan to use. The default setup requires several vCPUs of type `r7g.medium` and `g4dn.xlarge`.
- **Elastic Block Store (EBS):** At least 240 GB required; adjust based on your setup.
- **Elastic IPs (EIPs):** Ensure a quota for the necessary number of Elastic IPs.
- **GPU Instances:** If using GPU nodes, ensure your account supports the desired AWS EC2 instance sizes with GPU capabilities.

## Deployment Steps

1. **AWS CLI Login:**
   - Ensure you are logged in to the AWS CLI and have set the desired region:
     ```bash
     aws configure
     ```

2. **Run the Setup Script:**
   - Customize the following variables in the `setup_eks.sh` script to match your AWS environment:
     - **APP_INSTANCE_NAME:** Name your Marqo application instance.
     - **CLUSTER_NAME:** Define your Kubernetes cluster name.
     - **KEY_NAME:** Specify the name of your SSH key pair registered in AWS for node access.
     - **AWS_REGION:** Set to your preferred AWS region.
     - **INSTALL_GPU:** If deploying with GPU support, set INSTALL_GPU=true
     - **UBUNTU_AMI_ID:** If deploying with GPU support, configure the Ubuntu AMI ID. You can find list of AMIs for all regions here: https://cloud-images.ubuntu.com/aws-eks/

   - Execute the script:
     ```bash
     ./EKS/setup_eks.sh
     ```

     This script will:
     - Create an EKS cluster with the specified configurations.
     - Configure various node groups, including optional GPU nodes.
     - Apply necessary Kubernetes configurations for the EBS CSI driver and update kubeconfig for `kubectl` access.
    It will takes approximately 30~40 minutes until all pods are ready.

3. **Kubernetes Cluster Validation:**
   - After running the `setup_eks.sh` script, verify the health of the EKS cluster and Marqo pods:
     ```bash
     kubectl get pods --all-namespaces
     ```

4. **Test Marqo Endpoint:**
   - Find the external IP or hostname for the Marqo service:
     ```bash
     kubectl get svc -l "app=marqo" -o wide
     ```

5. **Test Marqo endpoint:**

```
export MARQO_CLUSTER_IP=$(kubectl get svc marqo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

python3 -m venv .venv
source .venv/bin/activate
pip install marqo
python test_marqo.py
```

## Additional Configuration

- **GPU Nodes:** For workloads requiring GPU, ensure the `marqonodes` node group is created with an appropriate VM size (`g4dn.xlarge`).
For GPU node, we recommend using Ubuntu AMIs. You can  king list of AMIs for AWS regions here: https://cloud-images.ubuntu.com/docs/aws/eks/
- **Custom Configurations:** Adjust the Helm chart values or the `setup_eks.sh` script for any custom deployment needs.

## Cleanup

To delete the EKS cluster and associated resources, run

```bash
./EKS/delete_cluster.sh
```

Ensure to replace `$CLUSTER_NAME` and `$AWS_REGION` with your actual cluster name and AWS region.


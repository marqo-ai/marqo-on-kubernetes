#!/bin/bash

# Login to AWS (This step is typically handled by configuring AWS CLI with `aws configure`)
# Make sure your AWS credentials are set up

# Set AWS Region and Account Details
export AWS_REGION='us-east-1' # Equivalent to eastus in Azure
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Define your application and cluster names
export APP_INSTANCE_NAME=marqo1
export CLUSTER_NAME=eks-ali4
export KEY_NAME=ali
# INSTALL_GPU is an environment variable that indicates whether to install GPU support
INSTALL_GPU=true
if [ "$INSTALL_GPU" = true ]; then
    # The AMI ID here is for us-east-1. You may need to change this for other regions
    # Find the latest EKS Ubuntu AMIs here: https://cloud-images.ubuntu.com/aws-eks/
    export UBUNTU_AMI_ID=ami-0d678772ad0cdc8d7
fi
# Create an EKS cluster using eksctl
# Note: eksctl simplifies the process of creating EKS clusters and node groups

AVAILABILITY_ZONES="us-east-1a,us-east-1b,us-east-1c"

eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION --zones $AVAILABILITY_ZONES

aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

eksctl utils associate-iam-oidc-provider --region=$AWS_REGION --cluster=$CLUSTER_NAME --approve

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve

eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole --force

eksctl update addon --name aws-ebs-csi-driver --version v1.11.4-eksbuild.1 --cluster $CLUSTER_NAME \
  --service-account-role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole --force

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespaadmin \
    --node-type t3.large \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name configserver \
    --node-type t3.large \
    --nodes 3 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespafeed \
    --node-type t3.large \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespaquery \
    --node-type t3.large \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespacontent \
    --node-type t3.large \
    --nodes 2 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed


# CPU
if [ "$INSTALL_GPU" = false ]; then
    eksctl create nodegroup \
        --cluster $CLUSTER_NAME \
        --region $AWS_REGION \
        --name marqonodes \
        --node-type t3.large \
        --nodes 1 \
        --ssh-access \
        --ssh-public-key $KEY_NAME \
        --managed
fi


if [ "$INSTALL_GPU" = true ]; then

    sed -e "s/{{CLUSTER_NAME}}/$CLUSTER_NAME/g" \
        -e "s/{{KEY_NAME}}/$KEY_NAME/g" \
        -e "s/{{REGION_NAME}}/$AWS_REGION/g" \
        -e "s/{{UBUNTU_AMI_ID}}/$UBUNTU_AMI_ID/g" \
        EKS/add_gpu.yaml > eks_gpu_node.yaml

    # Create Managed GPU Node Group in existing EKS Cluster
    eksctl create nodegroup --config-file=eks_gpu_node.yaml

    # Add the NVIDIA Helm repository:
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
        && helm repo update

    # Install the GPU Operator.
    # For more information, see the NVIDIA GPU Operator documentation.
    # https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html#install-gpu-operator
    helm install --wait --generate-name \
        -n gpu-operator --create-namespace \
        nvidia/gpu-operator
    rm -f eks_gpu_node.yaml
fi

helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=alpha.eksctl.io/nodegroup-name,gpu_enabled=$INSTALL_GPU > "${APP_INSTANCE_NAME}_manifest.yaml"
kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml" 
kubectl get pods --all-namespaces -w

rm -f "${APP_INSTANCE_NAME}_manifest.yaml"


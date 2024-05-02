#!/bin/bash

# Set AWS Region and Cluster Name
AWS_REGION=<Your AWS Region>
CLUSTER_NAME=<Your Cluster Name>

# Set the AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Update kubeconfig to use the EKS cluster
aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

# Delete Managed Node Groups
echo "Deleting managed node groups..."
eksctl delete nodegroup --cluster $CLUSTER_NAME --name vespaadmin --region $AWS_REGION --wait
eksctl delete nodegroup --cluster $CLUSTER_NAME --name configserver --region $AWS_REGION --wait
eksctl delete nodegroup --cluster $CLUSTER_NAME --name vespafeed --region $AWS_REGION --wait
eksctl delete nodegroup --cluster $CLUSTER_NAME --name vespaquery --region $AWS_REGION --wait
eksctl delete nodegroup --cluster $CLUSTER_NAME --name vespacontent --region $AWS_REGION --wait
eksctl delete nodegroup --cluster $CLUSTER_NAME --name marqonodes --region $AWS_REGION --wait

# Delete the EBS CSI driver addon
echo "Deleting the EBS CSI driver addon..."
eksctl delete addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --wait

# Delete the IAM service account for the EBS CSI driver
echo "Deleting the IAM service account..."
eksctl delete iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster $CLUSTER_NAME --wait

# Disassociate IAM OIDC provider
echo "Disassociating IAM OIDC provider..."
eksctl utils disassociate-iam-oidc-provider --region=$AWS_REGION --cluster=$CLUSTER_NAME --approve

# Delete the EKS cluster
echo "Deleting the EKS cluster..."
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION --wait

echo "Cluster and all associated resources have been deleted."

#!/bin/bash

# Login to AWS (This step is typically handled by configuring AWS CLI with `aws configure`)
# Make sure your AWS credentials are set up

# Set AWS Region and Account Details
export AWS_REGION='us-east-1' # Equivalent to eastus in Azure
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Define your application and cluster names
export APP_INSTANCE_NAME=marqo1
export CLUSTER_NAME=marqoeks
export KEY_NAME=ali
# Create an EKS cluster using eksctl
# Note: eksctl simplifies the process of creating EKS clusters and node groups

eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION ---version=1.29 

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
    --node-type r7g.medium \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name configserver \
    --node-type r7g.medium \
    --nodes 3 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespafeed \
    --node-type r7g.medium \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespaquery \
    --node-type r7g.medium \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name vespacontent \
    --node-type r7g.medium \
    --nodes 2 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed


# 
eksctl create nodegroup \
    --cluster $CLUSTER_NAME \
    --region $AWS_REGION \
    --name marqonodes \
    --node-type g4dn.xlarge \
    --nodes 1 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed

aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME


helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=eks.amazonaws.com/nodegroup > "${APP_INSTANCE_NAME}_manifest.yaml"

kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"

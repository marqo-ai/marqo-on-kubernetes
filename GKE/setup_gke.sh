#!/bin/bash
echo "Setting up GKE"
date

export PROJECT_ID=<Your GCP Project ID>
export APP_INSTANCE_NAME=<Your App Instance Name>
# set cluster name
export CLUSTER=<Your Cluster Name>
# set preferred zone and region
export REGION=<Your preferred region i.e us-central1>
export ZONE=<Your preferred zone i.e us-central1-a>
# INSTALL_GPU is an environment variable that indicates whether to install GPU support
INSTALL_GPU=false

gcloud services enable containerregistry.googleapis.com
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
gcloud container clusters create $CLUSTER
gcloud container clusters get-credentials "$CLUSTER"
# Create vespaadmin node pools.
gcloud container node-pools create vespaadmin --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1
# delete the default pool, so that we have a chance to create the needed node pools
gcloud container node-pools delete default-pool --cluster "$CLUSTER" --quiet
# Create vesapa configserver node pools. We need 3 nodes for configserver.
gcloud container node-pools create configserver --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 3
# Create vespa feed node pools.
gcloud container node-pools create vespafeed --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1
# Create vespa query node pools.
gcloud container node-pools create vespaquery --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1
# Create vespa content node pools. We need 2 nodes for content.
gcloud container node-pools create vespacontent --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 2
# Non-GPU
if [ "$INSTALL_GPU" = false ]; then
    gcloud container node-pools create marqonodes --cluster "$CLUSTER" --machine-type n2-standard-4 --disk-type pd-standard --disk-size=100 --num-nodes 1
fi
# GPU
if [ "$INSTALL_GPU" = true ]; then
    gcloud container node-pools create marqonodes --accelerator type=nvidia-tesla-t4,count=1,gpu-driver-version=default --cluster "$CLUSTER" --machine-type n1-standard-4 --disk-type pd-standard --disk-size=100 --num-nodes 1 --image-type=UBUNTU_CONTAINERD
fi


helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=cloud.google.com/gke-nodepool,gpu_enabled=$INSTALL_GPU,override_cuda_path=$INSTALL_GPU > "${APP_INSTANCE_NAME}_manifest.yaml"

kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"

echo "Setting completed for GKE"
date

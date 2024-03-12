#!/bin/bash
echo "Setting up GKE"
date

export PROJECT_ID=marqo-public
export APP_INSTANCE_NAME=marqo
# set cluster name
export CLUSTER=marqo-test
# set preferred zone and region
export REGION=us-central1
export ZONE=us-central1-a
# INSTALL_GPU is an environment variable that indicates whether to install GPU support
INSTALL_GPU=true

gcloud services enable containerregistry.googleapis.com
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
gcloud container clusters create $CLUSTER
gcloud container clusters get-credentials "$CLUSTER"
gcloud container node-pools create vespaadmin --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1
# delete the default pool, so that we have a chance to create the needed node pools
gcloud container node-pools delete default-pool --cluster "$CLUSTER" --quiet
gcloud container node-pools create configserver --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 3
gcloud container node-pools create vespafeed --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1
gcloud container node-pools create vespaquery --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1
gcloud container node-pools create vespacontent --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 2
# Non-GPU
if [ "$INSTALL_GPU" = false ]; then
    gcloud container node-pools create marqonodes --cluster "$CLUSTER" --machine-type n2-standard-4 --disk-type pd-standard --disk-size=100 --num-nodes 1
fi
# GPU
if [ "$INSTALL_GPU" = true ]; then
    gcloud container node-pools create marqo-nodes --accelerator type=nvidia-tesla-t4,count=1,gpu-driver-version=default --cluster "$CLUSTER" --machine-type n1-standard-4 --disk-type pd-standard --disk-size=100 --num-nodes 1 --image-type=UBUNTU_CONTAINERD
fi


helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=cloud.google.com/gke-nodepool,gpu_enabled=$INSTALL_GPU > "${APP_INSTANCE_NAME}_manifest.yaml"

kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"

echo "Setting completed for GKE"
date

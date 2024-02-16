#!/bin/bash

export PROJECT_ID=<your project-id>
gcloud config set project $PROJECT_ID

export APP_INSTANCE_NAME=<your app name>
gcloud services enable containerregistry.googleapis.com

# set cluster name
export CLUSTER=<your cluster name>

# set preferred zone and region
export REGION=<your region i.e australia-southeast1>
gcloud config set compute/region $REGION
export ZONE=<your zone i.e australia-southeast1-a>
gcloud config set compute/zone $ZONE

gcloud container clusters create $CLUSTER

gcloud container clusters get-credentials "$CLUSTER"

gcloud container node-pools create vespa-admin-nodes --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1

# delete the default pool, so that we have a chance to create the needed node pools
gcloud container node-pools delete default-pool --cluster "$CLUSTER" --quiet

gcloud container node-pools create vespa-configserver-nodes --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 3

gcloud container node-pools create vespa-feed-nodes --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1

gcloud container node-pools create vespa-query-nodes --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 1

gcloud container node-pools create vespa-content-nodes --cluster "$CLUSTER" --machine-type n1-standard-2 --disk-type pd-standard --disk-size=20 --num-nodes 2

# Non-GPU
gcloud container node-pools create marqo-nodes --cluster "$CLUSTER" --machine-type n2-standard-4 --disk-type pd-standard --disk-size=100 --num-nodes 1

# GPU
# for GPU set marqo.gpu_enabled to true in values.yaml
# gcloud container node-pools create marqo-nodes --accelerator type=nvidia-tesla-t4,count=1,gpu-driver-version=default --cluster "$CLUSTER" --machine-type n1-standard-4 --disk-type pd-standard --disk-size=100 --num-nodes 1 --image-type=UBUNTU_CONTAINERD

kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"

helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=cloud.google.com/gke-nodepool > "${APP_INSTANCE_NAME}_manifest.yaml"

kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml"
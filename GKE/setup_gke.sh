#!/bin/bash
set -e


# get the dir of this script and set a path to put files generated (and then read) during deploy/destroy
THIS_FILES_DIR_PATH="$(dirname "$(readlink -f "$0")")"
OUT_DIR="$THIS_FILES_DIR_PATH/../out"
CLUSTER_IP_FILE_PATH="${OUT_DIR}/marqo_cluster_ip_gke.env"

# source the envars
ENVARS_FILE_PATH="${THIS_FILES_DIR_PATH}/vars.env"
if [[ -f $ENVARS_FILE_PATH ]]; then
  set -a
  source $ENVARS_FILE_PATH
  set +a
else
  echo "No vars.env file found. Expected at ${ENVARS_FILE_PATH}"
fi


handle_error() {
    echo "An error occurred on line $1"
    exit 1
}
trap 'handle_error $LINENO' ERR


destroy_marqo_k8s() {
  echo "Destroying marqo cluster ${APP_INSTANCE_NAME} deployed on GKE"
  gcloud container clusters delete "$CLUSTER" --quiet
}


deploy_marqo_k8s() {
  echo "Deploying marqo cluster ${APP_INSTANCE_NAME} to GKE"

  mkdir -p $OUT_DIR

  # always execute from the top level dir
  cd "${THIS_FILES_DIR_PATH}/.."

  gcloud services enable containerregistry.googleapis.com
  gcloud services enable container.googleapis.com

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

  manifest_file_path="${OUT_DIR}/${APP_INSTANCE_NAME}_manifest_gke.yaml"
  helm template "${APP_INSTANCE_NAME}" chart/marqo-kubernetes --set cloudProviderMatcher=cloud.google.com/gke-nodepool,gpu_enabled=$INSTALL_GPU,override_cuda_path=$INSTALL_GPU > "$manifest_file_path"

  kubectl apply -f "$manifest_file_path"

  MARQO_CLUSTER_IP=$(kubectl get svc marqo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  echo "MARQO_CLUSTER_IP=$MARQO_CLUSTER_IP" > "$CLUSTER_IP_FILE_PATH"
  export "$MARQO_CLUSTER_IP"

  echo "marqo cluster ${APP_INSTANCE_NAME} deployed to GKE"
  date
}


# get user input args and perform the specified action
if (($# == 1)); then
  user_input=$1
  action_type=$(echo "$user_input" | tr '[:lower:]' '[:upper:]')
  if [[ "$action_type" == "DEPLOY" ]]; then
    deploy_marqo_k8s
  elif [[ "$action_type" == "DESTROY" ]]; then
    destroy_marqo_k8s
  else
    echo "Invalid input args. Options are: deploy or destroy."
    exit 1
  fi
else
  echo "Invalid input args. Exactly 1 required: deploy or destroy."
  exit 1
fi

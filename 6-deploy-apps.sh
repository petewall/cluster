#!/bin/bash

export KUBECONFIG=$(pwd)/cluster.yaml

# Deploy certbot
# Deploy ddclient

# Deploy Concourse
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm install concourse concourse/concourse --values concourse-values.yaml


# Deploy OTA client


# Deploy MQTT
#!/bin/bash

sudo microk8s enable dns
sudo microk8s enable helm3
sudo microk8s enable hostpath-storage
sudo microk8s enable ingress

echo "alias kubectl='sudo microk8s kubectl'" >> ~/.bash_aliases
echo "alias helm='sudo microk8s helm3'" >> ~/.bash_aliases

sudo microk8s add-node

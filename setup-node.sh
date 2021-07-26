#!/bin/bash

NODE_NUMBER=$1
if [ -z "${NODE_NUMBER}" ]; then
    echo "USAGE: setup-node.sh <node number>"
fi

# Change hostname
sudo sed --in-place --expression "s/raspberrypi/cluster-node-${NODE_NUMBER}/" /etc/hostname /etc/hosts

# Update existing packages
sudo apt-get update
sudo apt-get upgrade --yes --fix-missing
sudo apt autoremove

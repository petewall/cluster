#!/bin/bash

NODE_NUMBER=$1
if [ -z "${NODE_NUMBER}" ]; then
    echo "USAGE: setup-node.sh <node number>"
fi

# Change hostname
sudo sed --in-place --expression "s/ubuntu/cluster-node-${NODE_NUMBER}/" /etc/hostname
sudo hostname "cluster-node-${NODE_NUMBER}"

# Update existing packages
sudo apt-get update
sudo apt-get upgrade --yes --fix-missing
sudo apt autoremove
sudo apt install avahi-daemon  # Enables mDNS, which allows for cluster-node-#.local to be advertised

# Reboot to finish updates and get hostname to stick
sudo reboot
#!/bin/bash

# Update and install packages
sudo apt update
sudo apt upgrade --yes --fix-missing
sudo apt autoremove
sudo apt install net-tools vim

# Install Carvel tools
wget -O- https://carvel.dev/install.sh > install.sh
sudo bash install.sh
rm install.sh

# Create hostpath storage directory
sudo mkdir /data/cluster-storage
sudo chown kubernetes:kubernetes /data/cluster-storage/
cd /var/snap/microk8s/common
sudo rm default-storage
sudo ln -s /data/cluster-storage default-storage

# Add id_rsa.pub to ~/.ssh/authorized_keys

# Reboot to finish updates and get hostname to stick
sudo reboot

#!/bin/bash

USB_DRIVE_MOUNT_PATH=/mnt/usb

sudo mount --bind "${USB_DRIVE_MOUNT_PATH}" /var/snap/microk8s/common/default-storage/

sudo snap install microk8s --classic
sudo microk8s enable dns helm3 ingress storage

echo alias kubectl='sudo microk8s kubectl' >> ~/.bash_aliases
echo alias helm='sudo microk8s helm3' >> ~/.bash_aliases

# Setup

These are the steps required to deploy the nodes of the cluster

## M910q nodes

### Install the OS
* Download and flash a USB drive with [Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server)
* Install Ubuntu on the drive
  * M.2 drive with ext4 partition mounted at /
  * HDD with ext4 partition mounted at /data
  * Pre-install `microk8s` and `docker` snap packages and enable OpenSSH server
  * Set the hostname `cluster-node-x`, username and password
* On first boot
  * Update and add packages:
```
sudo apt update
sudo apt upgrade --yes --fix-missing
sudo apt autoremove
sudo apt install jq net-tools vim

wget -O- https://carvel.dev/install.sh > install.sh
sudo bash install.sh
rm install.sh
```
  * Set up hostpath storage drive:
```
sudo mkdir /data/cluster-storage
sudo chown kubernetes:kubernetes /data/cluster-storage/
cd /var/snap/microk8s/common
sudo rm default-storage
sudo ln -s /data/cluster-storage default-storage
```
  * Add id_rsa.pub to ~/.ssh/authorized_keys

### Set up Microk8s

```
sudo microk8s enable dns
sudo microk8s enable helm3
sudo microk8s enable hostpath-storage
sudo microk8s enable ingress

echo "alias kubectl='sudo microk8s kubectl'" >> ~/.bash_aliases
echo "alias helm='sudo microk8s helm3'" >> ~/.bash_aliases
```

### Add nodes

On the main-node:
```
sudo microkus add-node
```

On the new node:
```
sudo microk8s join ...
```

## Raspberry Pi node

### Install the OS
* Flash an SD card with a the [Ubuntu Server 22.04 LTS ARM64 image](https://ubuntu.com/raspberry-pi/server)
  * Before writing, click the gear icon and:
  * Set the hostname
  * Enable SSH
  * Set the username and password
* On first boot:
  * Update and add packages:
```
sudo apt update
sudo apt upgrade --yes --fix-missing
sudo apt autoremove
sudo apt install avahi-daemon jq net-tools vim  # avahi-daemon enables mDNS, which allows for cluster-node-#.local to be advertised
```
  * Install Microk8s
```
sudo snap install microk8s --classic
echo "alias kubectl='sudo microk8s kubectl'" >> ~/.bash_aliases
echo "alias helm='sudo microk8s helm3'" >> ~/.bash_aliases

sudo microk8s join ...
```

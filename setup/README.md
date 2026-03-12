# Setup

These are the steps required to deploy the nodes of the cluster

## Set up routing

1. Adjust DCHP settings to only allow serving IP addresses in the range 192.168.1.x - 192.168.1.250
   This allows for MetalLB to provision its own IP addresses for LoadBalancer services.

2. Define the `.localdomain` domain name for the network.
   This is used to find the NAS storage based on hostname, rather than IP address (which isn't static).

3. Set up port forwarding for 80, 443 to the Istio Ingress Gateway IP, typically 192.18.1.251.
   This will forward external HTTP and HTTPS traffic to the cluster, where Istio will forward it to the appropriate workload using VirtualServices.

## Installing Kubernetes

### Install the OS
* Download and flash a USB drive with [Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server)
* Install Ubuntu
  * HDD with ext4 partition mounted at /
  * M.2 drive with ext4 partition mounted at /data
  * Pre-install `microk8s` and `docker` snap packages and enable OpenSSH server
  * Set the hostname `cluster-node-x`, username and password
* On first boot
  * Update and add packages:

```bash
sudo apt update
sudo apt upgrade --yes --fix-missing
sudo apt autoremove
sudo apt install fwupd jq net-tools vim
```

  * Add id_rsa.pub to ~/.ssh/authorized_keys

### Set up Microk8s

There are a few built-in MicroK8s addons that we will enable. This simplifies the amount of workloads that
need to be deployed. The add-ons used are:

* [MetalLB](https://microk8s.io/docs/addon-metallb) - Provides LoadBalancer IP assignment for services. The IP range `192.168.1.251-192.168.1.254` is reserved outside the router's DHCP pool.

```bash
sudo microk8s enable metallb:192.168.1.251-192.168.1.254
echo "alias kubectl='sudo microk8s kubectl'" >> ~/.bash_aliases
```

> **Note:** Ingress is handled by Istio, deployed via GitOps in `infrastructure/istio/`.

### Add nodes

1. On the main-node, make generate the token required to join the cluster:

```bash
sudo microk8s add-node
```

2. On the new worker node, use that token:

```bash
sudo microk8s join ...
```

3. Make sure the new node has joined and is ready:

```bash
% kubectl get nodes
NAME             STATUS   ROLES    AGE    VERSION
cluster-node-1   Ready    <none>   450d   v1.32.1
cluster-node-2   Ready    <none>   450d   v1.32.1
```

## Deploying Workloads

After the Kubernetes cluster is ready, two things need to be manually installed 

### Install Flux

```
flux install
```

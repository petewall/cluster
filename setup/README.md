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
sudo apt install fwupd jq net-tools vim open-iscsi
```

  * `open-iscsi` is required on every node for the Synology CSI driver's iSCSI
    block volumes (`infrastructure/synology-csi/`). The node plugin has no
    bundled initiator — it uses the host's `iscsiadm`/`iscsid`. Enable the
    daemon and ensure the kernel module loads on boot:

```bash
sudo systemctl enable --now iscsid
echo iscsi_tcp | sudo tee /etc/modules-load.d/iscsi_tcp.conf
sudo modprobe iscsi_tcp
```

  * **Raise the iSCSI replacement timeout.** The default
    `node.session.timeo.replacement_timeout` is **120s** — shorter than a NAS
    reboot (DSM updates take minutes). When it expires the session is torn down,
    which fails in-flight writes and makes the kernel remount the ext4 volume
    **read-only**, crash-looping every iSCSI-backed pod (Postgres, HA, Mealie,
    Ollama — see `TROUBLESHOOTING.md`). Raising it to 900s makes a NAS reboot
    *pause* I/O and resume when the NAS returns, so the volumes self-recover:

```bash
# Default for future sessions:
sudo sed -i 's/^\s*node.session.timeo.replacement_timeout\s*=.*/node.session.timeo.replacement_timeout = 900/' /etc/iscsi/iscsid.conf
grep replacement_timeout /etc/iscsi/iscsid.conf          # verify it now reads 900

# Apply to any already-discovered target records:
sudo iscsiadm -m node -o update -n node.session.timeo.replacement_timeout -v 900

sudo systemctl restart iscsid
```

  > Existing *sessions* keep their old value until the volume re-attaches — so on
  > already-running nodes, either reboot the node (maintenance window) or
  > `kubectl delete` the iSCSI-backed pods once, which re-logs-in with the new
  > timeout. New sessions (and rebuilt nodes) pick it up automatically.

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

#### MetalLB IP allocations

Every address is pinned in git with a `metallb.universe.tf/loadBalancerIPs` annotation, so a rebuilt
cluster gets the same IPs back once Flux reconciles. The router and DNS are *outside* git, so they
must be redone by hand:

| IP | Service | Defined in | Outside-the-cluster setup |
| --- | --- | --- | --- |
| `192.168.1.251` | `istio-ingressgateway` (public) | `infrastructure/istio/istio-ingressgateway-helm-release.yaml` | Router port-forwards 80/443 to this IP. Public Cloudflare DNS records (`petewall.net`, `home`, `recipes`, `home.k8s`) point at the home WAN IP. |
| `192.168.1.252` | `postgres-lb` (CloudNativePG) | `infrastructure/databases/cluster.yaml` | None. LAN access to Postgres only. |
| `192.168.1.253` | `istio-lan-ingressgateway` (LAN-only) | `infrastructure/istio/istio-lan-ingressgateway-helm-release.yaml` | Cloudflare **DNS-only** (grey cloud) A records for each `*.internal.petewall.net` host → `192.168.1.253`. Do **not** port-forward this IP, since not being forwarded is what keeps it LAN-only. |
| `192.168.1.254` | *free* | | |

Moving or re-adding an address:

1. Change the annotation in git (or pick `.254` for a new service) and let Flux apply it.
2. Update anything in the last column. For `.253`, that is one Cloudflare A record per LAN hostname.
3. Keep the pool (`enable metallb:192.168.1.251-192.168.1.254`) outside the router's DHCP range
   (`.1`-`.250`), or the router can hand a LoadBalancer IP to another device.

The LAN gateway serves a wildcard cert for `*.internal.petewall.net`, issued via DNS-01 (Cloudflare API
token in the `cloudflare` secret in `cert-manager`, which needs `Zone:Zone:Read` and `Zone:DNS:Edit`).
To expose another LAN service, add a `VirtualService` on gateway
`istio-system/internal-petewall-net-gateway` and a DNS record; no new cert is needed.

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

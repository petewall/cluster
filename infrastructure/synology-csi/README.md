# synology-csi

Synology CSI driver ([SynologyOpenSource/synology-csi](https://github.com/SynologyOpenSource/synology-csi)),
vendored from `deploy/kubernetes/v1.20` and adapted for this cluster. Provides
**iSCSI block storage** (StorageClass `synology-iscsi`) for workloads that need
real block semantics — databases especially, which shouldn't run on NFS.

## Changes vs upstream

- **RBAC trimmed to least privilege** — the upstream cluster-wide `secrets`
  grant is removed from both the controller and node ClusterRoles. The DSM
  credential is consumed as a volume-mounted secret (no API access needed);
  `secret-rbac.yaml` adds a namespaced `Role` scoped to `client-info-secret` by
  name. Unused snapshot RBAC is dropped (no snapshotter deployed).
- **Controller de-privileged** — `privileged` / `SYS_ADMIN` /
  `allowPrivilegeEscalation` removed from all controller containers; it only
  makes DSM API calls and local-socket RPC. **Only the node plugin stays
  privileged**, which iSCSI attach/mount genuinely requires.
- **MicroK8s kubelet paths** — all `/var/lib/kubelet` paths in the node
  DaemonSet remapped to `/var/snap/microk8s/common/var/lib/kubelet`.
- Resource requests/limits added; `serviceAccount` → `serviceAccountName`.

## Prerequisites

### 1. On the Synology (DSM 7+)

- Install **SAN Manager** (Package Center) and ensure a storage pool + volume
  exist (`/volume1` — the same volume the NFS share uses).
- Create a **dedicated account** for the driver (e.g. `k8s-csi`):
  - It **must be in the `administrators` group** — DSM's LUN/iSCSI-target API
    only works for admins. This is a driver limitation, not a choice.
  - **Lock it down despite the admin status:** set **No Access** on every
    shared folder, deny all **Application Permissions** (File Station, etc.),
    disable its user home, and give it a strong unique password.
  - Optionally restrict its allowed source IPs to the node addresses.
- Use **HTTPS** (port 5001) so credentials aren't sent in cleartext on the LAN.
- Store the username/password in 1Password at `op://Lab/Synology Kubernetes CSI`.

### 2. On every node (Ubuntu)

The node plugin has no bundled iSCSI initiator — it `chroot`s to the host and
uses the host's `open-iscsi`. Install it on **both** nodes:

```bash
sudo apt-get update && sudo apt-get install -y open-iscsi
sudo systemctl enable --now iscsid
echo iscsi_tcp | sudo tee /etc/modules-load.d/iscsi_tcp.conf
sudo modprobe iscsi_tcp
```

### 3. Seal the DSM credentials

```bash
make client-info-secret.yaml    # reads op://Lab/Synology CSI, seals client-info-secret
```

Then uncomment `client-info-secret.yaml` in `kustomization.yaml` and commit.

## Validation (before relying on it)

Provision a test iSCSI PVC and mount it in a throwaway pod to confirm the driver
attaches cleanly under MicroK8s. This is the go/no-go gate before migrating any
real workload or removing the NFS driver.

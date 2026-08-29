# Troubleshooting

Runbooks for recurring failure modes in this cluster.

## iSCSI volumes go read-only / stateful pods crash after a NAS restart

**Problem:** Pods that use iSCSI storage are crashing or unable to write to their
storage.

**Quick solution:** If the Synology NAS was restarted recently, the iSCSI volumes
have likely gone read-only. **Delete the affected pods** — when they recreate they
open a fresh connection and re-mount read-write.

### Symptoms / how to identify it

- A stateful workload on `synology-iscsi` storage is in `CrashLoopBackOff` or
  logging write failures. The four iSCSI-backed apps are:
  - **`databases/postgres-1`** (CloudNativePG) — cluster status shows
    `Unable to create required cluster objects` / not Ready, the pod's restart
    count climbs fast, and its logs show `read-only file system`
    (e.g. `remove .../pgdata/postmaster.pid: read-only file system`).
  - **`mealie`**, **`homeassistant`**, **`ollama`** — their `/app/data`,
    `/config`, and model volumes are iSCSI too, so they can crash the same way.
- **Downstream effects** are often what you notice first: Mealie is down (its
  database is unreachable), Home Assistant logs recorder/DB errors.
- `kubectl describe pod` may show `FailedMount … MountVolume.MountDevice failed`.

> **Data is safe.** Read-only means writes were *blocked*, not corrupted. Postgres
> is crash-consistent, and ext4 runs fsck on the fresh mount. No restore needed.

### Cause / background

All of these volumes are **iSCSI block storage** on the Synology
(`synology-iscsi` StorageClass). When the NAS restarts — a DSM update, a power
blip, or a manual reboot:

1. The iSCSI target disappears for the length of the reboot (minutes).
2. The node's iSCSI session times out (`node.session.timeo.replacement_timeout`,
   default **120s**, which is shorter than any real reboot) and is torn down.
3. In-flight writes fail → the Linux kernel remounts the ext4 filesystem
   **read-only** (`errors=remount-ro`, the safe default).
4. That read-only state is **sticky at the pod/node mount level.** It does *not*
   clear when the NAS comes back, and — importantly — the container crashloop
   does *not* fix it: the volume is mounted once per pod and persists across
   container restarts, so the container just keeps restarting onto the same
   read-only filesystem. Only re-mounting the volume clears it.

NFS-backed volumes (e.g. `databases/postgres-backups`) are **not** affected — NFS
`hard` mounts block during the outage and resume when the server returns.

### Diagnose

```bash
export KUBECONFIG=./kubeconfig.yaml
kubectl get pods -A | grep -iE 'CrashLoop|Error'
kubectl logs postgres-1 -n databases -c postgres --tail=30 | grep -i 'read-only'
kubectl get cluster postgres -n databases      # CNPG not Ready?

# Is the NAS back and reachable?
kubectl run nastest --rm -i --restart=Never --image=busybox:1.36 -- sh -c \
  'nc -w5 -z storage.localdomain 3260 && echo iscsi-OK; nc -w5 -z storage.localdomain 5001 && echo dsm-OK'

# Is the CSI able to log into the DSM? (expect "Add DSM ... hostname")
kubectl logs synology-csi-controller-0 -n synology-csi -c csi-plugin --tail=20 \
  | grep -iE 'Add DSM|Failed to get|error'
```

### Resolve

Once the NAS is back **and** the CSI can log into the DSM, delete the affected
pods so each re-attaches its volume with a fresh read-write mount:

```bash
kubectl delete pod postgres-1 -n databases        # CNPG recreates it
kubectl delete pod --all -n mealie
kubectl delete pod --all -n homeassistant
kubectl delete pod --all -n ollama
```

Verify:

```bash
kubectl get cluster postgres -n databases         # -> "Cluster in healthy state", ready 1
kubectl get pods -n mealie; kubectl get pods -n homeassistant; kubectl get pods -n ollama
```

### If the volume won't re-attach

Errors like `Volume[...] is not found` or `Failed to get DSM[storage.localdomain]`
mean the CSI driver can't talk to the DSM (not data loss). Two common causes:

- **Stale login** — the CSI pods only log into the DSM at startup. Restart both:
  ```bash
  kubectl delete pod synology-csi-controller-0 -n synology-csi
  kubectl rollout restart daemonset/synology-csi-node -n synology-csi
  ```
- **TLS cert mismatch** — `certificate is valid for synology, not storage.localdomain`
  (the DSM regenerated its self-signed cert on an update). Fix is already in place
  (`insecureSkipVerify: true` in the client-info secret, see
  `infrastructure/synology-csi/`). If it recurs after a re-seal, delete the derived
  Secret to force sealed-secrets to re-unseal, then restart the CSI pods:
  ```bash
  kubectl delete secret client-info-secret -n synology-csi
  kubectl delete pod synology-csi-controller-0 -n synology-csi
  kubectl rollout restart daemonset/synology-csi-node -n synology-csi
  ```

### Prevent

- **Raise the iSCSI `replacement_timeout` on the nodes** (see `setup/README.md`)
  so a NAS reboot *pauses* block I/O and resumes when it returns, instead of
  remounting read-only. With that, the volumes self-recover and no pod deletes are
  needed.
- UPS + scheduled DSM updates so the NAS doesn't reboot unexpectedly.
- The nightly `pg_dump` job (`databases`) is the last-resort data safety net.

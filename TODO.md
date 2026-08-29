# TODO

## Control-plane / stuck-state detection & alerting

**Context:** On ~July 2 2026 (likely a power outage) the MicroK8s control plane on
`cluster-node-1` wedged — `kube-controller-manager`/scheduler held their leader
leases but stopped reconciling. Symptom surfaced days later as a sealed-secrets
pod that wouldn't start (its new pod was stuck on node-2, which also had a Calico
CNI `Unauthorized` failure). Fixed with `sudo microk8s stop && sudo microk8s start`
on node-1. See memory `cluster-topology-and-recovery.md`.

**Goal:** alert on this class of failure next time. The signals were already
flowing to Grafana Cloud (cluster `wallhouse`) via the `k8s-monitoring` chart —
we just had no alerts.

**Gotcha:** during the incident the wedged controllers reported *phantom-healthy*
status (DaemonSet `ready=2/2` stale, Deployment `Available=True`, node stayed
`Ready`), so naive "daemonset unavailable / deployment unavailable / node down"
alerts would NOT have fired. `generation != observedGeneration` also would NOT
have caught the original wedge (that lag only appeared once a rollout was forced).

### What's scraped today
- kubelet, cAdvisor, kube-state-metrics (metrics)
- cluster events → Loki (`clusterEvents.enabled: true`)
- NO control-plane component scraping (no kube-scheduler / kube-controller-manager jobs)

### Tasks (rough priority order)

1. **Add alert: pods stuck not-Running** (KSM, already scraped) — would have fired
   (pod stuck ~4 days):
   ```promql
   kube_pod_status_phase{phase="Pending"} == 1                                  # for: 20m
   kube_pod_container_status_waiting_reason{reason="ContainerCreating"} == 1    # for: 20m
   ```

2. **Add alert: FailedCreatePodSandBox events** (Loki, already shipping) — 25k+ of
   these `Unauthorized` events during the incident:
   ```logql
   sum(count_over_time({job="integrations/kubernetes/eventhandler"} |= "FailedCreatePodSandBox" [10m]))
   ```
   (verify the actual event job/label name in Loki)

   → Implement 1 & 2 as Grafana Cloud alert rules via `gcx`, GitOps-style.

3. **(Optional, most direct) Enable control-plane scraping** in
   `apps/monitoring/k8s-monitoring-helm-release.yaml`
   (`clusterMetrics.kube-scheduler` / `.kube-controller-manager`) to watch the
   wedge itself. Needs MicroK8s-specific setup (kubelite exposes these on-node with
   auth). Then alert on:
   - `workqueue_unfinished_work_seconds{name="daemonset"}` climbing
   - `scheduler_pending_pods` rising while `scheduler_schedule_attempts_total` flatlines
   - `leader_election_master_status == 1` while the above are stuck
   Not strictly needed — #1/#2 were sufficient and simpler.

4. **Fix memory note** `cluster-topology-and-recovery.md`: the generation-lag
   detector is overstated (wouldn't have caught the original wedge). The real
   detectors are pods-stuck-not-Running + FailedCreatePodSandBox events.

5. **(Infra, non-monitoring) Consider a UPS** for the nodes so an outage triggers a
   graceful shutdown instead of the wedge.


## Security hardening

Progressively enforce extra limits as more public services go live. Posture
surveyed 2026-08-27.

**Already done:**
- **petewall-net egress locked.** Its istio Sidecar is `REGISTRY_ONLY` with egress
  limited to `./*`, `istio-system/*`, `kube-system/*` — no external egress, only
  the control plane + DNS. Effectively ingress-only. ✅
- All meshed namespaces (petewall-net, mealie, homeassistant, dynamic-dns) already
  have STRICT mTLS (per-namespace `PeerAuthentication`) + ingress-only
  `AuthorizationPolicy` (allow only the ingress gateway).

**Gotcha — PSS vs istio-init:** meshed pods use an `istio-init` init container
needing `NET_ADMIN`/`NET_RAW`, which PSS `baseline`/`restricted` disallow. So PSS
`enforce` on a *meshed* namespace breaks pod creation **unless istio CNI is
installed** (it isn't yet). Non-meshed namespaces can enforce PSS freely.

### Tasks (security, rough priority order)

1. **Mesh-wide default STRICT mTLS** — add a `PeerAuthentication` named `default`
   in `istio-system` with `mtls.mode: STRICT`, so any new meshed namespace is
   STRICT by default. Zero risk (all current meshed workloads already STRICT).

2. **PSS visibility everywhere** — add `pod-security.kubernetes.io/warn:
   restricted` + `audit: restricted` labels to all app namespaces. Non-breaking;
   surfaces exactly what each workload violates on the path to `restricted`.

3. **PSS enforce baseline on non-meshed app namespaces** — `ollama`, `krr`,
   `databases`. Blocks host escapes/privileged if one is compromised. `warn`-check
   `databases` (CNPG) first before flipping `enforce` — it's the data tier.
   (`krr` is non-root/read-only → `restricted`-compatible.)

4. **Install istio CNI** (infrastructure/istio/) — removes the privileged
   `istio-init` from every meshed pod (hardening win in itself) AND unblocks PSS
   `restricted` enforcement on the meshed namespaces. The proper unlock for #2.

5. **NetworkPolicies on the data tier** — BIGGEST actual exposure: `databases`
   (Postgres) and `ollama` are not meshed and have **no NetworkPolicy**, so any
   pod cluster-wide can reach them directly. Add default-deny + allow-from
   {mealie, homeassistant, backup job} on `databases`, and allow-from {mealie,
   homeassistant, krr} on `ollama`. Closes lateral-movement paths. (MicroK8s
   Calico supports NetworkPolicy.)
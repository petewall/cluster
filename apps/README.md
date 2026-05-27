# Applications

Workloads I run on the cluster. Applied by Flux via the `apps`
[Kustomization](../cluster/apps.yaml), which `dependsOn` infrastructure.

* [petewall-net](./petewall-net) — Hugo-based site running [petewall.net](https://petewall.net).
* [monitoring](./monitoring) — Grafana Cloud agents (k8s-monitoring, synthetic monitoring, PDC).
* [ironwall](./ironwall) — CloudNativePG Postgres cluster backing the
  ironwall app. Managed by its own Flux Kustomization at
  [`../cluster/ironwall.yaml`](../cluster/ironwall.yaml) so it can be
  suspended independently; currently `suspend: true`.

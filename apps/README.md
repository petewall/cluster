# Applications

Workloads I run on the cluster. Applied by Flux via the `apps`
[Kustomization](../cluster/apps.yaml), which `dependsOn` infrastructure.

* [petewall-net](./petewall-net) — Hugo-based site running [petewall.net](https://petewall.net).
* [monitoring](./monitoring) — Grafana Cloud agents (k8s-monitoring, synthetic monitoring, PDC).

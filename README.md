# Cluster

This repository is the source of truth for my Kubernetes cluster. Flux runs
in the cluster and reconciles state from `main` — anything merged here lands
on the cluster within a minute or two.

1. [Setup](setup) the cluster (one-time, manual).
2. Bootstrap Flux from [`cluster/`](cluster) — see [cluster/README.md](cluster/README.md).
3. After that, Flux applies [`infrastructure/`](infrastructure) and [`apps/`](apps) automatically.

## Layout

```
cluster/           Flux entrypoint (Kustomization CRs, one per logical unit)
infrastructure/    Cluster-wide controllers and supporting resources
apps/              Workloads I run on the cluster
setup/             Manual steps for provisioning new nodes
```

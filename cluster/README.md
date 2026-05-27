# Cluster

Flux entrypoint for this cluster. After `flux bootstrap` is run with
`--path=cluster`, Flux watches this directory and applies anything it finds
here.

Each file is a Flux `Kustomization` that points at a path elsewhere in the
repo:

* [`infrastructure.yaml`](./infrastructure.yaml) — applies [`../infrastructure`](../infrastructure). Runs first, `wait: true`.
* [`apps.yaml`](./apps.yaml) — applies [`../apps`](../apps). `dependsOn: infrastructure`.
* [`ironwall.yaml`](./ironwall.yaml) — applies [`../apps/ironwall`](../apps/ironwall) as an independent Kustomization so it can be toggled with `spec.suspend`.

`flux-system/` is written by `flux bootstrap` and contains the controllers'
manifests plus the self-referential `GitRepository` + `Kustomization`. Do not
edit by hand — re-run `flux bootstrap` to update.

## Bootstrap

```bash
export KUBECONFIG=$PWD/kubeconfig.yaml
export GITHUB_TOKEN=...  # PAT with `repo` scope
flux bootstrap github \
  --owner=petewall \
  --repository=cluster \
  --branch=main \
  --path=cluster \
  --personal
```

## Day-to-day

```bash
flux get kustomizations --watch       # status of every Kustomization
flux reconcile kustomization apps --with-source   # force a pull + apply
flux suspend kustomization <name>     # pause reconcile (cluster keeps current state)
flux resume kustomization <name>      # opposite
```

## Adding a new app

Either add a subdirectory under [`../apps/`](../apps) and list it in
[`../apps/kustomization.yaml`](../apps/kustomization.yaml) (rides with the
shared `apps` Kustomization), or create a dedicated Flux Kustomization here
(like `ironwall.yaml`) if it needs an independent on/off switch or
reconcile cadence.

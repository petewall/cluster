# Infrastructure

Cluster-wide controllers and supporting resources. Applied by Flux via the
`infrastructure` [Kustomization](../cluster/infrastructure.yaml) with
`wait: true`, so [`apps/`](../apps) won't start applying until everything
here is `Ready`.

* [cert-manager](./cert-manager) — Certificate issuers and an internal self-signed CA.
* [dynamic-dns](./dynamic-dns) — Updates Cloudflare DNS records so the home IP stays reachable.
* [istio](./istio) — Service mesh + ingress gateway (replaces the MicroK8s NGINX addon).
* [sealed-secrets](./sealed-secrets) — [Bitnami Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) controller. Lets us commit encrypted secrets to git.
* [storage](./storage) — NFS CSI driver + StorageClass backed by the Synology NAS.

# Infrastructure Workloads

These workloads are deployed for as support to the application workloads:

* [Cert Manager](./cert-manager): Deploys Certificate Issuers and an internal self-signed CA.
* [Dynamic DNS](./dynamic-dns): Automatically update the DNS settings for my domains using Dynamic DNS.
* [Ingress Routes](./ingress-routes): 
* [Sealed Secrets](./sealed-secrets/): Deploys [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) which allows for secrets to be stored in GitOps.
* [Storage](./storage/): Deploys the NFS storage system to allow provisioning PVCs from Synology NAS

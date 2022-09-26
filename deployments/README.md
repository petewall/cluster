# Deployments

The standard deployments in to the cluster:

* [Cert Manager](cert-manager): Allows for automatically provisioning x.509 certificates.
* [Concourse](concourse): my favorite thing-doer, running nearly all of my CI/CD workloads.
* [Concourse secrets](concourse-secrets): the secrets that are used by the Concourse pipelines.
* [Ghost](ghost): an open-source blogging platform, running petewall.net (rip Pagemill).
* [Monitoring](monitoring): A set of services to deploy cluster monitoring, including Telegraf and InfluxDB for metrics gathering and Grafana for dashboards.
* [Network](network): network-related things:
  * DynamicDNS Client
    * Updates Google Domains records with the local IP address for domain names like `petewall.net`
  * Pi-hole
    * DNS server that blocks ad-traffic
* [secretgen-controller](secretgen-controller): an operator and CRDs used for generating secrets.

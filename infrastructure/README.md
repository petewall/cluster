# Infrastructure Workloads

These workloads are deployed for as support to the application workloads:

* [Cert Manager](cert-manager): Allows for automatically provisioning x.509 certificates.
* [Monitoring](monitoring): A set of services to deploy cluster monitoring, including Telegraf and InfluxDB for metrics gathering and Grafana for dashboards.
* [Network](network): network-related things:
  * DynamicDNS Client
    * Updates Google Domains records with the local IP address for domain names like `petewall.net`

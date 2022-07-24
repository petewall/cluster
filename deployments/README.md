# Deployments

The standard deployments in to the cluster.

## Network

This deploys network-related things:

* DynamicDNS Client
  * Updates Google Domains records with the local IP address for domain names like `petewall.net`
* [Pi-hole](https://pi-hole.net/)
  * DNS server that blocks ad-traffic
  * Also supplies DNS for domains that should not be exposed outside the network

## Cert Manager

[Cert Manager](https://cert-manager.io/) allows for automatically provisioning x.509 certificates.

## Ghost

[Ghost](https://ghost.org/) is an open-source blogging platform, running petewall.net (rip Pagemill).

## Concourse

[Concourse](https://concourse-ci.org/) is my favorite thing-doer, running nearly all of my CI/CD workloads.

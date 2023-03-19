# Network

This deploys systems that are used to assist and augment the networking of the cluster and the lab it is in.

## Components

### Dynamic DNS

[Dynamic DNS](https://en.wikipedia.org/wiki/Dynamic_DNS) is the method of updating DNS records dynamically by the client to ensure that they stay up to date. This is used because some ISPs don't allocate static IP addresses, but instead use public IPs that may change.

With [Google Domains](https://domains.google/), it's as simple as a cURL call to `https://domains.google.com/nic/update?hostname={hostname}` with an optional argument for `myip={ipaddress}`.

![Dynamic DNS architecture](images/architecture.png)

## Installing

```bash
make deploy
```

# Monitoring

A set of services to deploy cluster monitoring, including [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) and [InfluxDB](https://www.influxdata.com/products/influxdb-overview/) for metrics gathering and [Grafana](https://grafana.com/grafana/) for dashboards.

## Deployment process

This deployment utilizes the Helm charts for each service, but does not use Helm to deploy them. We utilize a combination of `helm`, `ytt`, and `vendir` to create a set of Kubernetes objects that then get deployed with `kapp`.

## Installing

```bash
make deploy
```

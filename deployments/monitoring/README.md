# Monitoring

This adds the data collectors and sends data to Grafana Cloud. This loosely follows the configuration instructions found on Grafana Cloud, which are essentially:

1. Deploy the operator Helm chart (I'm using vendir to fetch locally, and kapp to deploy)
2. Deploy the operator CRDs (which are stored inside the Helm chart, but not deployed by it)
3. Deploy the custom resource and supporting objects (copied from the integrations page)

## Installing

```bash
make deploy
```

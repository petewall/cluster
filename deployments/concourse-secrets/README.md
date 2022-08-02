# Concourse Secrets

This deploys Kubernetes secrets to the cluster so that they can be used within Concourse pipelines.
These are not secrets that Concourse itself needs, only secrets that are used by the pipelines.

All secrets should be stored in my 1Password password manager as the source of truth.

## Installing

```bash
make deploy
```

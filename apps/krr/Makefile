SHELL := /bin/bash

.PHONY: all
all: prometheus-secret.yaml github-secret.yaml

##@ KRR Prometheus read credentials (Grafana Cloud)
# Reuses the metrics instance + endpoint, but a SEPARATE access token scoped
# metrics:read (the alloy push token can't query). Create that token in the
# Grafana Cloud portal (Access Policies) and store it in 1Password first.
PROM_URL = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics Read/website")./api/prom
PROM_USER = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics Read/username")
PROM_TOKEN = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics Read/password")

prometheus-secret.yaml:
	kubectl create secret generic krr-prometheus \
		--namespace krr \
		--from-literal=url="$(PROM_URL)" \
		--from-literal=user="$(PROM_USER)" \
		--from-literal=token="$(PROM_TOKEN)" \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

##@ GitHub token for the KRR report issue (fine-grained PAT, repo-scoped, issues:write)
GITHUB_TOKEN = $(shell op read --account my.1password.com "op://Lab/cluster KRR issue creator/password")

github-secret.yaml:
	kubectl create secret generic krr-github \
		--namespace krr \
		--from-literal=token="$(GITHUB_TOKEN)" \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

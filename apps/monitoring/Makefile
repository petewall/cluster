SHELL := /bin/bash

.PHONY: all

all: grafana-cloud-secret.yaml synthetic-monitoring-secret.yaml synthetic-monitoring-agent-deployment.yaml

grafana-cloud-secret.yaml:
	kubectl create secret generic grafana-cloud \
		--namespace monitoring \
		--from-literal=metricsUrl=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/website") \
		--from-literal=metricsUsername=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/username") \
		--from-literal=metricsPassword=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/password") \
		--from-literal=logsUrl=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Logs/website") \
		--from-literal=logsUsername=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Logs/username") \
		--from-literal=logsPassword=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Logs/password") \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

SYNTHETIC_MONITORING_API_URL = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Synthetic Monitoring/website")
SYNTHETIC_MONITORING_API_TOKEN = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Synthetic Monitoring/password")

synthetic-monitoring-secret.yaml:
	kubectl create secret generic synthetic-monitoring-api \
		--namespace monitoring \
		--from-literal=api-token="$(SYNTHETIC_MONITORING_API_TOKEN)" \
		--from-literal=api-server="$(SYNTHETIC_MONITORING_API_URL)" \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

synthetic-monitoring-agent-deployment.yaml: overlays/synthetic-monitoring-agent-deployment-mods.yaml
		set -o pipefail; \
		curl -fsSL https://raw.githubusercontent.com/grafana/synthetic-monitoring-agent/main/examples/kubernetes/deployment.yaml | \
		ytt -f - -f $< > $@
	

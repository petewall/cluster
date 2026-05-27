SHELL := /bin/bash

.PHONY: all

all: grafana-cloud-secret.yaml synthetic-monitoring-secret.yaml synthetic-monitoring-agent-deployment.yaml

##@ Grafana Cloud
grafana-cloud-secret.yaml:
	kubectl create secret generic grafana-cloud \
		--namespace monitoring \
		--from-literal=metricsUrl=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/website")./api/prom/push \
		--from-literal=metricsUsername=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/username") \
		--from-literal=metricsPassword=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/password") \
		--from-literal=logsUrl=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Logs/website")./loki/api/v1/push \
		--from-literal=logsUsername=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Logs/username") \
		--from-literal=logsPassword=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Logs/password") \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

##@ Synthetic Monitoring
SYNTHETIC_MONITORING_API_URL = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Synthetic Monitoring/website")
SYNTHETIC_MONITORING_API_TOKEN = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud Synthetic Monitoring/password")
SYNTHETIC_MONITORING_AGENT_VERSION = $(shell curl -s https://api.github.com/repos/grafana/synthetic-monitoring-agent/releases/latest | jq -r '.tag_name')

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
	ytt -f - -f $< --data-value version=$(SYNTHETIC_MONITORING_AGENT_VERSION) > $@

##@ Private Datasource Connect
PDC_CLUSTER = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud PDC Access Policy Token/cluster")
PDC_USERNAME = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud PDC Access Policy Token/username")
PDC_TOKEN = $(shell op read --account my.1password.com "op://Lab/Grafana Cloud PDC Access Policy Token/password")
PDC_VERSION = $(shell curl -s https://api.github.com/repos/grafana/pdc-agent/releases/latest | jq -r '.tag_name')
pdc-agent-secret.yaml:
	kubectl create secret generic grafana-pdc-agent \
		--namespace monitoring \
		--from-literal=cluster="$(PDC_CLUSTER)" \
		--from-literal=hosted-grafana-id="$(PDC_USERNAME)" \
		--from-literal=token="$(PDC_TOKEN)" \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

pdc-agent-deployment.yaml: overlays/pdc-agent-deployment-mods.yaml
	set -o pipefail; \
	curl -fsSL https://raw.githubusercontent.com/grafana/pdc-agent/main/production/kubernetes/pdc-agent-deployment.yaml | \
			ytt -f - -f $< > $@
# 			ytt -f - -f $< --data-value version=$(PDC_VERSION) > $@

##@ Kubernetes Monitoring Helm chart
k8s-monitoring-helm-values.yaml: k8s-monitoring-helm-release.yaml
	yq 'select(document_index == 1) | .spec.values' $< > $@

k8s-monitoring-helm-output.yaml: k8s-monitoring-helm-values.yaml
	helm template --repo https://grafana.github.io/helm-charts k8s-monitoring k8s-monitoring -f $< > $@

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

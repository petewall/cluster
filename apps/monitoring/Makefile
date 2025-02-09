SHELL := /bin/bash

.PHONY: all

all: grafana-cloud-secret.yaml

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

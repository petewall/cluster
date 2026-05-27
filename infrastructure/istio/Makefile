SHELL := /bin/bash

.PHONY: all
all: kiali-grafana-cloud-secret.yaml

kiali-grafana-cloud-secret.yaml:
	kubectl create secret generic kiali-grafana-cloud \
		--namespace istio-system \
		--from-literal=grafanaUrl='"$(shell op read --account my.1password.com "op://Lab/petewall.grafana.net Kiali SA/website")"' \
		--from-literal=grafanaUser='"$(shell op read --account my.1password.com "op://Lab/petewall.grafana.net Kiali SA/username")"' \
		--from-literal=grafanaToken=$(shell op read --account my.1password.com "op://Lab/petewall.grafana.net Kiali SA/password") \
		--from-literal=prometheusUrl='"$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/website")./api/prom"' \
		--from-literal=prometheusUser='"$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/username")"' \
		--from-literal=prometheusPassword=$(shell op read --account my.1password.com "op://Lab/Grafana Cloud Metrics/password") \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

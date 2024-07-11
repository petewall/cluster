SHELL := /bin/bash

.PHONY: deploy delete

vendor/k8s-monitoring/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

kubernetes-monitoring.yaml: vendor/k8s-monitoring/Chart.yaml values.yaml extraConfig.river
	helm template k8s-monitoring vendor/k8s-monitoring \
		--namespace monitoring \
		--values <(ytt --file values.yaml \
			--data-value metrics.host="$(shell op read "op://Lab/Grafana Cloud Metrics/website")" \
			--data-value metrics.username="$(shell op read "op://Lab/Grafana Cloud Metrics/username")" \
			--data-value metrics.password="$(shell op read "op://Lab/Grafana Cloud Metrics/password")" \
			--data-value logs.host="$(shell op read "op://Lab/Grafana Cloud Logs/website")" \
			--data-value logs.username="$(shell op read "op://Lab/Grafana Cloud Logs/username")" \
			--data-value logs.password="$(shell op read "op://Lab/Grafana Cloud Logs/password")" \
			--data-value traces.host="$(shell op read "op://Lab/Grafana Cloud Traces/website")" \
			--data-value traces.username="$(shell op read "op://Lab/Grafana Cloud Traces/username")" \
			--data-value traces.password="$(shell op read "op://Lab/Grafana Cloud Traces/password")" \
		) \
		--set-file extraConfig=extraConfig.river \
		| kbld -f - > kubernetes-monitoring.yaml

deploy: namespace.yaml kubernetes-monitoring.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file namespace.yaml \
		--file kubernetes-monitoring.yaml

delete:
	kapp delete --app monitoring

SHELL := /bin/bash

.PHONY: deploy

vendor/kubernetes-monitoring/charts/kubernetes-monitoring/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

kubernetes-monitoring.yaml: vendor/kubernetes-monitoring/charts/kubernetes-monitoring/Chart.yaml values.yaml concourse.river unifipoller.river
	helm template kubernetes-monitoring vendor/kubernetes-monitoring/charts/kubernetes-monitoring \
		--namespace monitoring \
		--values <(ytt --file values.yaml \
			--data-value metrics.host="$(shell op read "op://Lab/Grafana Cloud Metrics/website")" \
			--data-value metrics.username="$(shell op read "op://Lab/Grafana Cloud Metrics/username")" \
			--data-value metrics.password="$(shell op read "op://Lab/Grafana Cloud Metrics/password")" \
			--data-value logs.host="$(shell op read "op://Lab/Grafana Cloud Logs/website")" \
			--data-value logs.username="$(shell op read "op://Lab/Grafana Cloud Logs/username")" \
			--data-value logs.password="$(shell op read "op://Lab/Grafana Cloud Logs/password")" \
			--data-value-file extraConfig=<(cat concourse.river unifipoller.river) \
		) \
		| kbld -f - > kubernetes-monitoring.yaml

deploy: namespace.yaml kubernetes-monitoring.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file namespace.yaml \
		--file kubernetes-monitoring.yaml

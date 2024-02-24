SHELL := /bin/bash

.PHONY: deploy delete

vendor/k8s-monitoring/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

vendor/kepler/Chart.yaml: vendir.yml vendir.lock.yml
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
		| ytt -f remove-tests-and-hooks-overlay.yaml -f - \
		| kbld -f - > kubernetes-monitoring.yaml

kepler.yaml: vendor/kepler/Chart.yaml kepler-values.yaml
	helm template kepler vendor/kepler \
		--namespace monitoring \
		--values kepler-values.yaml \
		> kepler.yaml

deploy: kapp-config.yaml namespace.yaml kubernetes-monitoring.yaml kepler.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file kapp-config.yaml \
		--file namespace.yaml \
		--file kubernetes-monitoring.yaml \
		--file kepler.yaml

delete:
	kapp delete --app monitoring

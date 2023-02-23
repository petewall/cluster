SHELL := /bin/bash

.PHONY: deploy

vendor/grafana-agent-operator/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

grafana-agent-operator.yaml: vendor/grafana-agent-operator/Chart.yaml
	helm template grafana-agent-operator vendor/grafana-agent-operator \
		--namespace monitoring --create-namespace \
		--skip-tests \
		| kbld -f - > grafana-agent-operator.yaml

deploy: namespace.yaml grafana-agent-operator.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file kapp-config.yaml \
		--file namespace.yaml \
		--file vendor/grafana-agent-operator/crds \
		--file grafana-agent-operator.yaml \
		--file <(ytt --data-value cluster.name=wallhouse --file grafana-agent.yaml) \
		--file kube-state-metrics.yaml \
		--file service-monitor-cadvisor.yaml \
		--file service-monitor-kubelet.yaml \
		--file <(ytt --file secrets.yaml \
			--data-value metrics.username="$(shell op read "op://Lab/Grafana Cloud Metrics/username")" \
			--data-value metrics.password="$(shell op read "op://Lab/Grafana Cloud Metrics/password")" \
			--data-value logs.username="$(shell op read "op://Lab/Grafana Cloud Logs/username")" \
			--data-value logs.password="$(shell op read "op://Lab/Grafana Cloud Logs/password")" \
		)

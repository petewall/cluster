SHELL := /bin/bash

.PHONY: deploy

vendor/grafana-agent/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

vendor/kube-state-metrics/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

vendor/node-exporter/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

grafana-agent.yaml: vendor/grafana-agent/Chart.yaml grafana-agent-values.yaml
	helm template grafana-agent vendor/grafana-agent \
		--namespace monitoring \
		--values grafana-agent-values.yaml \
		| kbld -f - > grafana-agent.yaml

kube-state-metrics.yaml: vendor/kube-state-metrics/Chart.yaml
	helm template kube-state-metrics vendor/kube-state-metrics --namespace monitoring | kbld -f - > kube-state-metrics.yaml

node-exporter.yaml: vendor/node-exporter/Chart.yaml
	helm template node-exporter vendor/node-exporter --namespace monitoring --set nameOverride=node-exporter | kbld -f - > node-exporter.yaml

deploy: namespace.yaml grafana-agent.yaml grafana-agent-config.yaml grafana-agent-config.river.lib.txt kube-state-metrics.yaml node-exporter.yaml secrets.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file namespace.yaml \
		--file grafana-agent.yaml \
		--file <(ytt --file grafana-agent-config.yaml \
			--file grafana-agent-config.river.lib.txt \
			--data-value cluster_name="wallhouse" \
			--data-value metrics.url="$(shell op read "op://Lab/Grafana Cloud Metrics/website")" \
			--data-value logs.url="$(shell op read "op://Lab/Grafana Cloud Logs/website")" \
		) \
		--file kube-state-metrics.yaml \
		--file node-exporter.yaml \
		--file <(ytt --file secrets.yaml \
			--data-value metrics.username="$(shell op read "op://Lab/Grafana Cloud Metrics/username")" \
			--data-value metrics.password="$(shell op read "op://Lab/Grafana Cloud Metrics/password")" \
			--data-value logs.username="$(shell op read "op://Lab/Grafana Cloud Logs/username")" \
			--data-value logs.password="$(shell op read "op://Lab/Grafana Cloud Logs/password")" \
			--data-value storage_snmp.username="$(shell op read "op://Lab/Storage SNMP/username")" \
			--data-value storage_snmp.password="$(shell op read "op://Lab/Storage SNMP/password")" \
			--data-value storage_snmp.protocol="$(shell op read "op://Lab/Storage SNMP/protocol")" \
			--data-value storage_snmp.priv_protocol="$(shell op read "op://Lab/Storage SNMP/privacy/protocol")" \
			--data-value storage_snmp.priv_password="$(shell op read "op://Lab/Storage SNMP/privacy/password")" \
		)

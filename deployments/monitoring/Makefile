SHELL := /bin/bash

.PHONY: clean deploy

clean:
	rm -rf charts/* influxdb.yaml grafana.yaml telegraf.yaml

vendor/grafana-agent/production/kubernetes/agent-bare.yaml: vendir.yml vendir.lock.yml
	vendir sync

grafana-agent.yaml: vendor/grafana-agent/production/kubernetes/agent-bare.yaml
	cat vendor/grafana-agent/production/kubernetes/agent-bare.yaml | NAMESPACE=monitoring envsubst | kbld -f - > grafana-agent.yaml

vendor/grafana-agent/production/kubernetes/agent-loki.yaml:
	vendir sync

grafana-agent-loki.yaml: vendor/grafana-agent/production/kubernetes/agent-loki.yaml
	cat vendor/grafana-agent/production/kubernetes/agent-loki.yaml | NAMESPACE=monitoring envsubst | kbld -f - > grafana-agent-loki.yaml

vendor/kube-state-metrics/Chart.yaml:
	vendir sync

kube-state-metrics.yaml: vendor/kube-state-metrics/Chart.yaml
	helm template kube-state-metrics vendor/kube-state-metrics --namespace monitoring | kbld -f - > kube-state-metrics.yaml

deploy: namespace.yaml grafana-agent.yaml grafana-agent-loki.yaml grafana-agent-cm.yaml grafana-agent-logs-cm.yaml kube-state-metrics.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file namespace.yaml \
		--file grafana-agent.yaml \
		--file <(ytt -f grafana-agent-cm.yaml \
			--data-values-file data.yaml \
			--data-value metrics.url="$(shell op read "op://Lab/Grafana Cloud Metrics/website")" \
			--data-value metrics.username="$(shell op read "op://Lab/Grafana Cloud Metrics/username")" \
			--data-value metrics.password="$(shell op read "op://Lab/Grafana Cloud Metrics/password")" \
			--data-value logs.url="$(shell op read "op://Lab/Grafana Cloud Logs/website")" \
			--data-value logs.username="$(shell op read "op://Lab/Grafana Cloud Logs/username")" \
			--data-value logs.password="$(shell op read "op://Lab/Grafana Cloud Logs/password")" \
		) \
		--file <(ytt -f grafana-agent-logs-cm.yaml \
			--data-values-file data.yaml \
			--data-value metrics.url="$(shell op read "op://Lab/Grafana Cloud Metrics/website")" \
			--data-value metrics.username="$(shell op read "op://Lab/Grafana Cloud Metrics/username")" \
			--data-value metrics.password="$(shell op read "op://Lab/Grafana Cloud Metrics/password")" \
			--data-value logs.url="$(shell op read "op://Lab/Grafana Cloud Logs/website")" \
			--data-value logs.username="$(shell op read "op://Lab/Grafana Cloud Logs/username")" \
			--data-value logs.password="$(shell op read "op://Lab/Grafana Cloud Logs/password")" \
		) \
		--file grafana-agent-loki.yaml \
		--file kube-state-metrics.yaml

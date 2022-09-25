SHELL := /bin/bash

.PHONY: clean deploy

clean:
	rm -rf charts/* influxdb.yaml grafana.yaml telegraf.yaml

charts/influxdb/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync

charts/grafana/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync

charts/telegraf/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync

influxdb.yaml: charts/influxdb/Chart.yaml influxdb-values.yaml
	helm template influxdb charts/influxdb \
		--namespace monitoring --create-namespace \
		--values influxdb-values.yaml \
		| kbld -f - > influxdb.yaml

grafana.yaml: charts/grafana/Chart.yaml grafana-values.yaml
	helm template grafana charts/grafana \
		--namespace monitoring --create-namespace \
		--values grafana-values.yaml \
		| kbld -f - > grafana.yaml

telegraf.yaml: charts/telegraf/Chart.yaml telegraf-values.yaml
	helm template telegraf-ds charts/telegraf \
		--namespace monitoring --create-namespace \
		--values telegraf-values.yaml \
		| kbld -f - > telegraf.yaml

deploy: config.yaml namespace.yaml secrets.yaml influxdb.yaml grafana.yaml telegraf.yaml
	kapp deploy \
		--app monitoring \
		--diff-changes \
		--into-ns monitoring \
		--file config.yaml \
		--file namespace.yaml \
		--file <(ytt --file secrets.yaml \
			--data-value grafana.username="$(shell op read "op://Lab/Grafana/username")" \
			--data-value grafana.password="$(shell op read "op://Lab/Grafana/password")") \
		--file influxdb.yaml \
		--file grafana.yaml \
		--file telegraf.yaml

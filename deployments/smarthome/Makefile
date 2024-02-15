SHELL := /bin/bash
.PHONY: deploy

label-cluster:
	kubectl label node cluster-node-0 hardware.co2meter=true

deploy: namespace.yaml co2meter.yaml
	kapp deploy \
		--app smarthome \
		--diff-changes \
		--file namespace.yaml \
		--file <(kbld --file co2meter.yaml)

delete:
	kapp delete -a smarthome

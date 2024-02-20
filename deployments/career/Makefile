SHELL := /bin/bash
.PHONY: deploy

deploy: namespace.yaml event-logger.yaml okr-service.yaml
	kapp deploy \
		--app okr-service \
		--diff-changes \
		--file namespace.yaml \
		--file <(kbld --file okr-service.yaml) \
		--file <(kbld --file event-logger.yaml)

delete:
	kapp delete -a okr-service

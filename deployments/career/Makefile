SHELL := /bin/bash
.PHONY: deploy

deploy: namespace.yaml okr-service.yaml
	kapp deploy \
		--app okr-service \
		--diff-changes \
		--file namespace.yaml \
		--file <(kbld --file okr-service.yaml)

delete:
	kapp delete -a okr-service
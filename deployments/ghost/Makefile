SHELL := /bin/bash

.PHONY: deploy

deploy: ghost.yaml
	kapp deploy \
		--app ghost \
		--diff-changes \
		--into-ns ghost \
		--file <(kbld -f ghost.yaml) \
		--file <(kbld -f ghost-db.yaml) \
		--diff-changes

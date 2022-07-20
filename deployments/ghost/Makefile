SHELL := /bin/bash

deploy: ghost.yaml
	kapp deploy \
		--app ghost \
		--diff-changes \
		--into-ns ghost \
		--file ghost.yaml \
		--diff-changes

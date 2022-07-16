SHELL := /bin/bash

deploy: ghost.yaml
	kapp deploy \
		--app ghost \
		--into-ns ghost \
		--file ghost.yaml \
		--diff-changes

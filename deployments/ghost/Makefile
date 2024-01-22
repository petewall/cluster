SHELL := /bin/bash

.PHONY: deploy

deploy: ghost.yaml
	kapp deploy \
		--app ghost \
		--diff-changes \
		--into-ns ghost \
		--file <(kbld -f ghost.yaml) \
		--file <(ytt --file ghost-db.yaml \
			--data-value-file ghostdb.password=<(op read "op://Lab/Ghost DB Root Password/password") \
		| kbld -f -) \
		--diff-changes

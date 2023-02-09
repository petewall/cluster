SHELL := /bin/bash

.PHONY: clean deploy

clean:
	rm -rf vendor

vendor/opencost/kubernetes/opencost.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

opencost.yaml: vendor/opencost/kubernetes/opencost.yaml set-envs-overlay.yaml set-namespace-overlay.yaml
	ytt \
		--file vendor/opencost/kubernetes/opencost.yaml \
		--file set-envs-overlay.yaml \
		--file set-namespace-overlay.yaml \
		| kbld -f - > opencost.yaml

deploy: opencost.yaml service-monitor.yaml secret.yaml
	kapp deploy \
		--app opencost \
		--diff-changes \
		--file opencost.yaml \
		--file service-monitor.yaml \
		--file <(ytt --file secret.yaml \
			--data-value url="$(shell op read "op://Lab/Opencost Metrics Viewer Key/hostname")" \
			--data-value username="$(shell op read "op://Lab/Opencost Metrics Viewer Key/username")" \
			--data-value password="$(shell op read "op://Lab/Opencost Metrics Viewer Key/credential")" \
		)


SHELL := /bin/bash

ddclient-secret.yaml:
	kubectl create secret generic ddclient -n network --from-file <(op read op://Lab/Dynamic\ DNS/ddclient.conf) --dry-run=client -o yaml > ddclient-secret.yaml

deploy: namespace.yaml ddclient-secret.yaml ddclient.yaml
	kapp deploy -a network --diff-changes -f namespace.yaml -f ddclient-secret.yaml -f ddclient.yaml

SHELL := /bin/bash

ddclient-secret.yaml:
	kubectl create secret generic ddclient -n network --from-file ddclient.conf=<(op read op://Lab/Dynamic\ DNS/ddclient.conf) --dry-run=client -o yaml > ddclient-secret.yaml

deploy: namespace.yaml ddclient-secret.yaml ddclient.yaml pi-hole.yaml
	kapp deploy -a network \
		--diff-changes \
		-f namespace.yaml \
		-f ddclient-secret.yaml \
		-f ddclient.yaml \
		-f pi-hole.yaml

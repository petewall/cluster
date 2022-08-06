SHELL := /bin/bash

.PHONY: deploy

ddclient-secret.yaml:
	kubectl create secret generic ddclient -n network --from-file ddclient.conf=<(op read op://Lab/Dynamic\ DNS/ddclient.conf) --dry-run=client -o yaml > ddclient-secret.yaml

deploy: namespace.yaml ddclient-secret.yaml ddclient.yaml pi-hole.yaml
	kapp deploy -a network \
		--diff-changes \
		-f namespace.yaml \
		-f ddclient-secret.yaml \
		-f ddclient.yaml \
		-f <(ytt --file pi-hole.yaml \
			--data-value password="$(shell op read "op://Lab/Pi Hole/password")")

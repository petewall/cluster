SHELL := /bin/bash

.PHONY: deploy

charts/pihole/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

# pi-hole.yaml: charts/pihole/Chart.yaml pi-hole-values.yaml
# 	helm template pihole charts/pihole \
# 		--namespace network \
# 		--values pi-hole-values.yaml \
# 		> pi-hole.yaml

# pi-hole-password.yaml:
# 	kubectl create secret generic pihole-password -n network --from-file password=<(op read "op://Lab/Pi Hole/password") --dry-run=client -o yaml > pi-hole-password.yaml

ddclient-secret.yaml:
	kubectl create secret generic ddclient -n network --from-file ddclient.conf=<(op read op://Lab/Dynamic\ DNS/ddclient.conf) --dry-run=client -o yaml > ddclient-secret.yaml

deploy: namespace.yaml ddclient-secret.yaml ddclient.yaml
	kapp deploy -a network \
		--into-ns network \
		--diff-changes \
		-f namespace.yaml \
		-f ddclient-secret.yaml \
		-f <(kbld -f ddclient.yaml)

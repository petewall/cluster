SHELL := /bin/bash

.PHONY: all
all: client-info-secret.yaml

##@ Synology CSI DSM connection credentials
# A DEDICATED DSM account for the CSI driver (see README). Store it in 1Password.
# Host/port default to the LAN NAS over HTTPS; override on the command line if needed.
DSM_HOST ?= storage.localdomain
DSM_PORT ?= 5001
DSM_USER = $(shell op read --account my.1password.com "op://Lab/Synology Kubernetes CSI/username")
DSM_PASS = $(shell op read --account my.1password.com "op://Lab/Synology Kubernetes CSI/password")

# The driver reads a client-info.yml file (mounted from this secret). We seal the
# whole file as the `client-info.yml` key of the `client-info-secret` secret.
#
# insecureSkipVerify: the DSM's self-signed cert is CN=synology, but we connect
# as storage.localdomain (SAN mismatch), so strict verification fails and the
# driver can't log in. TLS is still used (encrypted) — just unverified. Clean
# follow-up: give the DSM a cert with SAN=storage.localdomain, then drop this.
client-info-secret.yaml:
	kubectl create secret generic client-info-secret \
		--namespace synology-csi \
		--from-file=client-info.yml=<(printf 'clients:\n- host: %s\n  port: %s\n  https: true\n  insecureSkipVerify: true\n  username: %s\n  password: %s\n' \
			"$(DSM_HOST)" "$(DSM_PORT)" "$(DSM_USER)" "$(DSM_PASS)") \
		-o yaml --dry-run=client | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

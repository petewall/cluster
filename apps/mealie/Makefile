SHELL := /bin/bash

.PHONY: all
all: mealie-db-password.yaml

##@ Mealie's Postgres password (same value as the CNPG role, re-sealed for the
# mealie namespace since sealed secrets are namespace-scoped).
MEALIE_DB_PASS = $(shell op read --account my.1password.com "op://Lab/Mealie Database/password")

mealie-db-password.yaml:
	kubectl create secret generic mealie-db-password \
		--namespace mealie \
		--from-literal=password="$(MEALIE_DB_PASS)" \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

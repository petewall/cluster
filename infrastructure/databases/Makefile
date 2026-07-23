SHELL := /bin/bash

.PHONY: all
all: mealie-db-password.yaml homeassistant-db-password.yaml

##@ CloudNativePG managed-role passwords (basic-auth sealed secrets)
# Each role's password lives in 1Password. The homeassistant password is also
# what you put in the HAOS recorder db_url. CNPG requires the secret to be
# type kubernetes.io/basic-auth with username matching the role name, and the
# cnpg.io/reload label so rotations apply without a restart.
MEALIE_DB_PASS = $(shell op read --account my.1password.com "op://Lab/Mealie Database/password")
HOMEASSISTANT_DB_PASS = $(shell op read --account my.1password.com "op://Lab/Home Assistant Database/password")

mealie-db-password.yaml:
	kubectl create secret generic mealie-db-password \
		--namespace databases \
		--type kubernetes.io/basic-auth \
		--from-literal=username=mealie \
		--from-literal=password="$(MEALIE_DB_PASS)" \
		--dry-run=client -o yaml | \
	kubectl label --local -f - cnpg.io/reload=true --dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

homeassistant-db-password.yaml:
	kubectl create secret generic homeassistant-db-password \
		--namespace databases \
		--type kubernetes.io/basic-auth \
		--from-literal=username=homeassistant \
		--from-literal=password="$(HOMEASSISTANT_DB_PASS)" \
		--dry-run=client -o yaml | \
	kubectl label --local -f - cnpg.io/reload=true --dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

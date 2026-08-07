SHELL := /bin/bash

.PHONY: all
all: homeassistant-secrets.yaml

##@ HA secrets.yaml (sealed) — holds the recorder Postgres connection string.
# Reuses the existing `homeassistant` CNPG role (its password lives in the
# "Home Assistant Database" 1Password entry) against the isolated
# homeassistant_k8s database it owns. Username is the role name, hardcoded.
# IMPORTANT: the password must be URL-safe (letters/digits) — it's embedded in
# the db_url below.
HA_DB_PASS = $(shell op read --account my.1password.com "op://Lab/Home Assistant Database/password")
DB_URL = postgresql://homeassistant:$(HA_DB_PASS)@postgres-rw.databases.svc.cluster.local/homeassistant_k8s?sslmode=require

homeassistant-secrets.yaml:
	kubectl create secret generic homeassistant-secrets \
		--namespace homeassistant \
		--from-literal=secrets.yaml="recorder_db_url: $(DB_URL)" \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

SHELL := /bin/bash

.PHONY: all
all: tesserae-secret-key.yaml

##@ Tesserae connector-secret encryption key (TESSERAE_SECRET_KEY).
# Generate once and store in 1Password, e.g.:
#   op item create --category Password --vault Lab --title 'Tesserae Secret Key' \
#     'password=$(openssl rand -hex 32)'
# Keep it stable — rotating it forces every stored connector credential to be
# re-entered in the UI.
TESSERAE_SECRET_KEY = $(shell op read --account my.1password.com "op://Lab/Tesserae Secret Key/password")

tesserae-secret-key.yaml:
	kubectl create secret generic tesserae-secret-key \
		--namespace tesserae \
		--from-literal=secret-key="$(TESSERAE_SECRET_KEY)" \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

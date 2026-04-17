SHELL := /bin/bash

.PHONY: all
all: ironwall-db-app.yaml

ironwall-db-app.yaml:
	kubectl create secret generic ironwall-db-app \
		--namespace ironwall \
		--type kubernetes.io/basic-auth \
		--from-literal username=$(shell op read --account my.1password.com "op://Lab/ironwall-db/username") \
		--from-literal password=$(shell op read --account my.1password.com "op://Lab/ironwall-db/password") \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

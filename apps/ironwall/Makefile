SHELL := /bin/bash

.PHONY: all
all: ironwall-db-user.yaml

ironwall-db-user.yaml:
	kubectl create secret generic ironwall-db-user \
		--namespace ironwall \
		--type kubernetes.io/basic-auth \
		--from-literal username=$(shell op read --account my.1password.com "op://Lab/ironwall-db/username") \
		--from-literal password=$(shell op read --account my.1password.com "op://Lab/ironwall-db/password") \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

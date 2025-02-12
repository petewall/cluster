SHELL := /bin/bash

.PHONY: all
all: ghost-user.yaml ghost-db.yaml

ghost-user.yaml:
	kubectl create secret generic ghost-user \
		--namespace ghost \
		--from-literal ghost-password=$(shell op read --account my.1password.com "op://Lab/Ghost User/password") \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

ghost-db.yaml:
	kubectl create secret generic ghost-db \
		--namespace ghost \
		--from-literal mysql-password=$(shell op read --account my.1password.com "op://Lab/Ghost Database/password") \
		--from-literal mysql-root-password=$(shell op read --account my.1password.com "op://Lab/Ghost Database/password") \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

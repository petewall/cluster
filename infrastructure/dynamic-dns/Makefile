SHELL := /bin/bash

.PHONY: all
all: cloudflare-secret.yaml

cloudflare-secret.yaml:
	kubectl create secret generic cloudflare \
		--namespace dynamic-dns \
		--from-literal token=$(shell op read --account my.1password.com "op://Lab/Cloudflare DNS API Token/password") \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

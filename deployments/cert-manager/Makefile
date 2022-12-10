SHELL := /bin/bash
.PHONY: deploy

deploy: ca.yaml issuer.yaml
	kapp deploy -a cert-manager-issuers -f ca.yaml -f issuer.yaml

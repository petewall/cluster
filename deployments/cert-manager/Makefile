SHELL := /bin/bash
.PHONY: deploy

deploy: issuer.yaml
	kapp deploy -a cert-manager-issuers -f issuer.yaml

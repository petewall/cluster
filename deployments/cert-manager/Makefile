SHELL := /bin/bash

.PHONY: deploy

deploy: issuer.yaml
	kapp deploy -a cert-manager -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml
	kapp deploy -a cert-manager-issuers -f issuer.yaml

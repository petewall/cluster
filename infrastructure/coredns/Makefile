SHELL := /bin/bash

HELM_REPO_URL = https://coredns.github.io/helm

.PHONY: all
all: coredns.yaml

coredns.yaml: values.yaml
	helm repo add coredns $(HELM_REPO_URL) --force-update
	helm template coredns coredns/coredns \
		--namespace kube-system \
		-f values.yaml > $@

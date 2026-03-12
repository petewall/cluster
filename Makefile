kubeconfig.yaml:
	ssh kubernetes@cluster-node-1 microk8s config > kubeconfig.yaml
	chmod 600 kubeconfig.yaml

sealed-secrets.cert:
	kubeseal --fetch-cert --controller-name sealed-secrets --controller-namespace kube-system > sealed-secrets.cert


.PHONY: lint lint-yaml
lint: lint-yaml

YAML_FILES := $(shell find . -name '*.yaml')
lint-yaml:
	yamllint $(YAML_FILES)

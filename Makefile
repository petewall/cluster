##@ General

kubeconfig.yaml: ## Fetch the kubeconfig for access to the cluster.
	ssh kubernetes@cluster-node-1 microk8s config > kubeconfig.yaml
	chmod 600 kubeconfig.yaml

sealed-secrets.cert: ## Fetch the sealed secrets certificate for sealing new or rotated secrets.
	kubeseal --fetch-cert --controller-name sealed-secrets --controller-namespace kube-system > sealed-secrets.cert

##@ GitOps

.PHONY: bootstrap
bootstrap: ## Run Flux Bootstrap to enable GitOps.
	GITHUB_TOKEN=$(shell op read --account my.1password.com "op://Lab/Kubernetes Cluster Flux Bootstrap Token/password") \
	flux bootstrap github \
		--owner=petewall \
		--repository=cluster \
		--branch=main \
		--path=cluster \
		--personal \
		--components-extra=image-reflector-controller,image-automation-controller \
		--read-write-key

##@ Testing

.PHONY: lint lint-yaml
lint: lint-yaml ## Run all linters.

YAML_FILES := $(shell find . -name '*.yaml')
lint-yaml: ## Lint YAML files.
	yamllint $(YAML_FILES)


##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

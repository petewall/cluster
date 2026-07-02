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

.PHONY: lint lint-yaml lint-kube render clean
lint: lint-yaml lint-kube ## Run all linters.

YAML_FILES := $(shell find . -name '*.yaml' -not -path './.temp/*')
lint-yaml: ## Lint YAML files.
	yamllint $(YAML_FILES)

# Every Flux HelmRelease (tracked files only; '^kind:' is the top-level doc kind,
# so sourceRef references and the flux-system components are excluded).
HELMRELEASES := $(shell git ls-files -z '*.yaml' | xargs -0 grep -lE '^kind: HelmRelease' | grep -v flux-system)
RENDERED_HELMRELEASES := $(foreach hr,$(HELMRELEASES),.temp/rendered/$(patsubst %-helm-release.yaml,%,$(notdir $(hr)))-output.yaml)

render: $(RENDERED_HELMRELEASES) ## Render every HelmRelease to .temp/rendered/<chart>-output.yaml.

# Every input file kustomize reads for these overlays, so a change to any of them
# re-renders the output (targets with no prerequisites are never rebuilt once they exist).
INFRASTRUCTURE_SOURCES := $(shell find infrastructure -type f)
APPS_SOURCES := $(shell find apps -type f)

.temp/rendered/infrastructure.yaml: $(INFRASTRUCTURE_SOURCES)
	@mkdir -p .temp/rendered
	kustomize build infrastructure > $@

.temp/rendered/apps.yaml: $(APPS_SOURCES)
	@mkdir -p .temp/rendered
	kustomize build apps > $@

# Generate one rule per HelmRelease (works on make 3.81, unlike a
# secondary-expansion pattern rule). Each output depends only on its own release
# file, so `make` re-renders just the charts whose source changed.
define render_rule
.temp/rendered/$(patsubst %-helm-release.yaml,%,$(notdir $(1)))-output.yaml: $(1)
	@mkdir -p .temp/rendered
	./scripts/lint/render-helmrelease.sh $$< $$@
endef
$(foreach hr,$(HELMRELEASES),$(eval $(call render_rule,$(hr))))

lint-kube: $(RENDERED_HELMRELEASES) .temp/rendered/infrastructure.yaml .temp/rendered/apps.yaml ## Lint rendered manifests for known-bad configs (kube-linter).
	kube-linter lint .temp/rendered --config .kube-linter.yaml

.temp/kube-linter.sarif: $(RENDERED_HELMRELEASES) .temp/rendered/infrastructure.yaml .temp/rendered/apps.yaml
	kube-linter lint .temp/rendered --config .kube-linter.yaml --format=sarif > $@

clean: ## Remove generated/temporary files (.temp/).
	rm -rf .temp

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

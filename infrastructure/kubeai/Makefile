SHELL := /bin/bash

.PHONY: all
all: huggingface-secret.yaml

# HuggingFace token (auth-only, no permissions) used by KubeAI to pull gated
# models from hf://. Sealed with the cluster's public cert so it's safe to
# commit. KubeAI expects the data key "token"; to use it, set
# secrets.huggingface.create=false and secrets.huggingface.name=huggingface
# in kubeai-helm-release.yaml, and add huggingface-secret.yaml to
# kustomization.yaml.
huggingface-secret.yaml:
	kubectl create secret generic huggingface \
		--namespace kubeai \
		--from-literal token=$(shell op read --account my.1password.com "op://Private/Hugging Face/public-token") \
		--dry-run=client -o yaml | \
	kubeseal --cert ../../sealed-secrets.cert --format yaml > $@

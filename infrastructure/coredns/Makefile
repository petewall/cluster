SHELL := /bin/bash

ANTI_AFFINITY := '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":[{"labelSelector":{"matchLabels":{"k8s-app":"kube-dns"}},"topologyKey":"kubernetes.io/hostname"}]}}}}}}'

.PHONY: all
all:
	kubectl patch deployment coredns -n kube-system -p $(ANTI_AFFINITY)
	kubectl patch deployment coredns -n kube-system -p '{"spec":{"replicas":2}}'

kubeconfig.yaml:
	ssh kubernetes@cluster-node-1 microk8s config > kubeconfig.yaml
	chmod 600 kubeconfig.yaml


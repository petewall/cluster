kubeconfig.yaml:
	ssh ubuntu@cluster-node-0.local sudo microk8s config > kubeconfig.yaml
	chmod 600 kubeconfig.yaml

ssh:
	ssh ubuntu@cluster-node-0.local

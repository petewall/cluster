kubeconfig.yaml:
	ssh ubuntu@192.168.2.7 sudo microk8s config > kubeconfig.yaml
	chmod 600 kubeconfig.yaml

ssh:
	ssh ubuntu@192.168.2.7

kubeconfig.yaml:
	ssh kubernetes@192.168.2.11 microk8s config > kubeconfig.yaml
	chmod 600 kubeconfig.yaml

ssh:
	ssh kubernetes@192.168.2.11

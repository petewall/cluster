SHELL := /bin/bash

.PHONY: clean deploy

clean:
	rm -rf chart csi-driver-nfs.yaml

chart/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

csi-driver-nfs.yaml: chart/Chart.yaml values.yaml
	helm template csi-driver-nfs chart \
		--namespace kube-system \
		--values values.yaml \
		| kbld -f - > csi-driver-nfs.yaml

deploy: csi-driver-nfs.yaml synology-nfs-storageclass.yaml
	kapp deploy \
		--app storage \
		--diff-changes \
		--file csi-driver-nfs.yaml \
		--file synology-nfs-storageclass.yaml

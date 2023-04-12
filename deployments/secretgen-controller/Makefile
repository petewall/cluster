SHELL := /bin/bash

.PHONY: deploy

deploy:
	kapp deploy --app secretgen-controller \
		--file https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/latest/download/release.yml

SHELL := /bin/bash

.PHONY: deploy

ddclient-secrets.yaml: ddclient-secret-template.yaml
	echo "---" > ddclient-secrets.yaml
	ytt --file ddclient-secret-template.yaml \
		--data-value url="petewall.net" \
		--data-value-file username=<(op read "op://Lab/petewall.net Dynamic DNS/username") \
		--data-value-file password=<(op read "op://Lab/petewall.net Dynamic DNS/password") \
		>> ddclient-secrets.yaml
	echo "---" >> ddclient-secrets.yaml
	ytt --file ddclient-secret-template.yaml \
		--data-value url="ci.petewall.net" \
		--data-value-file username=<(op read "op://Lab/ci.petewall.net Dynamic DNS/username") \
		--data-value-file password=<(op read "op://Lab/ci.petewall.net Dynamic DNS/password") \
		>> ddclient-secrets.yaml

ddclient-jobs.yaml: ddclient-job-template.yaml
	echo "---" > ddclient-jobs.yaml
	ytt --file ddclient-job-template.yaml --data-value url="petewall.net" >> ddclient-jobs.yaml
	echo "---" >> ddclient-jobs.yaml
	ytt --file ddclient-job-template.yaml --data-value url="ci.petewall.net" >> ddclient-jobs.yaml

deploy: namespace.yaml ddclient-jobs.yaml ddclient-secrets.yaml
	kapp deploy -a network \
		--into-ns network \
		--diff-changes \
		-f namespace.yaml \
		-f ddclient-secrets.yaml \
		-f <(kbld -f ddclient-jobs.yaml)

SHELL := /bin/bash

.PHONY: deploy

dynamic-dns-secrets.yaml: dynamic-dns-secret-template.yaml
	echo "---" > dynamic-dns-secrets.yaml
	ytt --file dynamic-dns-secret-template.yaml \
		--data-value url="petewall.net" \
		--data-value-file username=<(op read "op://Lab/petewall.net Dynamic DNS/username") \
		--data-value-file password=<(op read "op://Lab/petewall.net Dynamic DNS/password") \
		>> dynamic-dns-secrets.yaml
	echo "---" >> dynamic-dns-secrets.yaml
	ytt --file dynamic-dns-secret-template.yaml \
		--data-value url="ci.petewall.net" \
		--data-value-file username=<(op read "op://Lab/ci.petewall.net Dynamic DNS/username") \
		--data-value-file password=<(op read "op://Lab/ci.petewall.net Dynamic DNS/password") \
		>> dynamic-dns-secrets.yaml

dynamic-dns-jobs.yaml: dynamic-dns-job-template.yaml
	echo "---" > dynamic-dns-jobs.yaml
	ytt --file dynamic-dns-job-template.yaml --data-value url="petewall.net" >> dynamic-dns-jobs.yaml
	echo "---" >> dynamic-dns-jobs.yaml
	ytt --file dynamic-dns-job-template.yaml --data-value url="ci.petewall.net" >> dynamic-dns-jobs.yaml

deploy: namespace.yaml dynamic-dns-jobs.yaml dynamic-dns-secrets.yaml
	kapp deploy -a network \
		--into-ns network \
		--diff-changes \
		-f namespace.yaml \
		-f dynamic-dns-secrets.yaml \
		-f <(kbld -f dynamic-dns-jobs.yaml)

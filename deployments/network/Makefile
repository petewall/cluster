SHELL := /bin/bash

.PHONY: deploy

secrets.yaml: secrets-template.yaml
	ytt --file secrets-template.yaml \
		--data-value-file cloudflare.token=<(op read --account my.1password.com "op://Lab/Cloudflare DNS API Token/password") \
		>> secrets.yaml

dynamic-dns-jobs.yaml: dynamic-dns-job-template.yaml
	echo "---" > dynamic-dns-jobs.yaml
	ytt --file dynamic-dns-job-template.yaml --data-value domain="petewall.net" --data-value-file script=dynamic-dns-cloudflare.sh >> dynamic-dns-jobs.yaml
	echo "---" >> dynamic-dns-jobs.yaml
	ytt --file dynamic-dns-job-template.yaml --data-value domain="ci.petewall.net" --data-value-file script=dynamic-dns-cloudflare.sh >> dynamic-dns-jobs.yaml

deploy: namespace.yaml dynamic-dns-jobs.yaml secrets.yaml unifipoller.yaml
	kapp deploy -a network \
		--into-ns network \
		--diff-changes \
		-f namespace.yaml \
		-f secrets.yaml \
		-f dynamic-dns-jobs.yaml \
		-f <(ytt -f unifipoller.yaml \
			--data-value-file username=<(op read --account my.1password.com "op://Lab/unifipoller/username") \
			--data-value-file password=<(op read --account my.1password.com "op://Lab/unifipoller/password") \
			| kbld -f-)
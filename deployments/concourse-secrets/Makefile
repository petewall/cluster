SHELL := /bin/bash

.PHONY: deploy

deploy: secrets.yaml
	kapp deploy \
		--app concourse-secrets \
		--diff-changes \
		--into-ns concourse-main \
		--file namespace.yaml \
		--file <(ytt --file secrets.yaml \
			--data-value-file dockerhub.username=<(op read "op://Private/Docker Hub/username") \
			--data-value-file dockerhub.password=<(op read "op://Private/Docker Hub/personal access token") \
			--data-value-file github.access_token=<(op read "op://Lab/GitHub/access token") \
			--data-value-file github.private_key=<(op read "op://Lab/GitHub/private key") \
			--data-value-file nasa.apikey=<(op read "op://Private/NASA API/credential") \
			--data-value-file wifi.ssid=<(op read "op://Private/Home WiFi/network name") \
			--data-value-file wifi.password=<(op read "op://Private/Home WiFi/wireless network password"))

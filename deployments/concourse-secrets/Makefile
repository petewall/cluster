SHELL := /bin/bash

deploy: secrets.yaml
	kapp deploy \
		--app concourse-secrets \
		--diff-changes \
		--into-ns concourse-main \
		--file <(ytt --file secrets.yaml \
			--data-value dockerhub.username="$(shell op read "op://Private/Docker Hub/username")" \
			--data-value dockerhub.password="$(shell op read "op://Private/Docker Hub/personal access token")" \
			--data-value github.access_token="$(shell op read "op://Lab/GitHub/access token")" \
			--data-value-file github.private_key=<(op read "op://Lab/GitHub/private key") \
			--data-value wifi.ssid="$(shell op read "op://Private/Home WiFi/network name")" \
			--data-value wifi.password="$(shell op read "op://Private/Home WiFi/wireless network password")")

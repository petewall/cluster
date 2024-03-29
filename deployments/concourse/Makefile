SHELL := /bin/bash

.PHONY: clean deploy delete

clean:
	rm -rf chart concourse.yaml

chart/Chart.yaml: vendir.yml vendir.lock.yml
	vendir sync --locked

concourse.yaml: chart/Chart.yaml values.yaml
	helm template concourse chart \
		--namespace concourse --create-namespace \
		--values <(ytt --file values.yaml \
			--data-value pgusername="$(shell op read "op://Lab/Concourse PostgreSQL/username")" \
			--data-value pgpassword="$(shell op read "op://Lab/Concourse PostgreSQL/password")" \
			--data-value username="$(shell op read op://Private/Concourse/username)") \
		| kbld -f - > concourse.yaml

deploy: concourse.yaml namespace.yaml
	kapp deploy \
		--app concourse \
		--diff-changes \
		--map-ns default=concourse \
		--map-ns concourse=concourse \
		--map-ns monitoring=monitoring \
		--file namespace.yaml \
		--file <(ytt --file secrets.yaml \
			--data-value username="$(shell op read op://Private/Concourse/username)" \
			--data-value password="$(shell op read op://Private/Concourse/password)") \
		--file concourse.yaml

delete:
	kapp delete --app concourse

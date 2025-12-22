.PHONY: check lint validate template package clean install-deps pre-commit checkov trivy dependency-build

VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0")

dependencies:
	helm dependency build

validate: dependencies
	helm template . --namespace kuack-system | kubeconform -summary -output pretty \
		-schema-location default \
		-schema-location "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"

template: dependencies
	helm template . --debug --namespace kuack-system

checkov: dependencies
	helm template . --namespace kuack | checkov --directory . \
      --output cli \
      --config-file .checkovignore.yaml \
      --skip-resources-without-violations

trivy:
	trivy config \
		--ignorefile .trivyignore.yaml \
		--exit-code 1 \
		.

lint:
	ct lint --config ct.yaml --charts .

check: validate lint template trivy checkov

package: dependency-build
	helm package . --version $(VERSION) --app-version $(VERSION)

dependency-update:
	helm dependency update

install-deps:
	pre-commit install --install-hooks

dry-run: dependency-build
	helm install --dry-run --debug $(CHART_NAME) . --namespace kuack-system

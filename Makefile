# docker-registry.helm test suite
#
# These targets delegate to tests/test.sh so behaviour is identical whether you
# use `make` or call the scripts directly (handy on Windows/Git Bash where make
# may be absent). Examples:
#   make bootstrap
#   make test-offline          # static + unit, no cluster
#   make test-all              # everything incl. cluster integration
#   make test-integration ARGS="default htpasswd"
SHELL := bash
TESTS := tests/test.sh
ARGS  ?=

.PHONY: help bootstrap docs lint test-docs test-static test-unit test-integration test-offline test-all clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Install/verify test tooling (helm, helm-unittest, kubeconform, helm-docs)
	@bash $(TESTS) bootstrap

docs: ## Regenerate README.md from values.yaml + README.md.gotmpl (helm-docs)
	@helm-docs --sort-values-order=file

lint: ## helm lint --strict only
	@helm lint --strict .

test-docs: ## Doc layer: README drift check + values.schema.json validation
	@bash $(TESTS) docs

test-static: ## Layer 1: lint + render + kubeconform + invariants (no cluster)
	@bash $(TESTS) static

test-unit: ## Layer 2: helm-unittest template assertions (no cluster)
	@bash $(TESTS) unit

test-integration: ## Layer 3: install on the current kube context + probe
	@bash $(TESTS) integration $(ARGS)

test-offline: ## Static + unit (everything that needs no cluster)
	@bash $(TESTS) offline

test-all: ## Static + unit + integration
	@bash $(TESTS) all

clean: ## Remove any leftover test namespaces from interrupted runs
	@kubectl get ns -o name 2>/dev/null | grep -E 'namespace/drtest' \
	  | xargs -r kubectl delete --wait=false || true

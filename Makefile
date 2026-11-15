SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

include .env

# All
.PHONY: all
all: init validate plan

# Helm docs
.PHONY: docs
docs:
	helm-docs

# Helm repo setup
.PHONY: init
init:
	@if [[ "x$(HELM_URL)" != "x" ]] ; then helm repo add $(HELM_REPO) $(HELM_URL) ; helm repo update ; fi

# Helm validate
.PHONY: validate
validate: docs
	yamllint .
	for f in $(shell find helm -iname Chart.yaml -exec dirname {} \;) ; do helm lint $$f ; done

# Helm plan
.PHONY: plan
plan:
	helm diff upgrade --allow-unreleased --context 5 --namespace $(NAMESPACE) -f values.yaml $(HELM_RELEASE) $(HELM_CHART)

# Helm list
.PHONY: list
list:
	helm -n $(NAMESPACE) list
	kubectl -n $(NAMESPACE) get all

# Helm deploy
.PHONY: deploy
deploy:
	if [ -f .before ] ; then bash .before ; fi
	helm upgrade --install --history-max $(HELM_HISTORY) --timeout $(HELM_TIMEOUT) --wait --create-namespace --namespace $(NAMESPACE) -f values.yaml $(HELM_RELEASE) $(HELM_CHART)
	if [ -f .after ] ; then bash .after ; fi
	helm -n $(NAMESPACE) list
	kubectl -n $(NAMESPACE) get all

# Helm clean / uninstall
.PHONY: clean
clean:
	helm -n $(NAMESPACE) uninstall $(HELM_RELEASE)
	helm -n $(NAMESPACE) list
	kubectl -n $(NAMESPACE) get all

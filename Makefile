ENV ?= dev
DIR := envs/$(ENV)

.PHONY: help fmt validate lint security test integration init plan apply

help: ## Show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

fmt: ## Format all Terraform
	terraform fmt -recursive

validate: ## Validate every module and environment (no backend)
	@for d in bootstrap modules/* envs/*; do \
	  echo "==> $$d"; \
	  terraform -chdir=$$d init -backend=false -input=false >/dev/null && terraform -chdir=$$d validate || exit 1; \
	done

lint: ## tflint across the repo
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

security: ## Checkov security scan
	checkov --config-file .checkov.yaml

test: ## Fast mocked tests (no AWS)
	terraform -chdir=modules/vpc init -backend=false -input=false >/dev/null
	terraform -chdir=modules/vpc test

integration: ## Real-AWS Terratest (costs money; needs credentials)
	cd test && go mod tidy && RUN_INTEGRATION=1 go test -v -timeout 30m ./...

init: ## Init an env: make init ENV=dev TF_STATE_BUCKET=...
	@test -n "$(TF_STATE_BUCKET)" || (echo "Set TF_STATE_BUCKET" && exit 1)
	terraform -chdir=$(DIR) init -backend-config="bucket=$(TF_STATE_BUCKET)"

plan: ## Plan an env: make plan ENV=prod
	terraform -chdir=$(DIR) plan -out=tfplan

apply: ## Apply the saved plan
	terraform -chdir=$(DIR) apply tfplan

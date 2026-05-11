SHELL := /bin/bash

.PHONY: help init-config doctor configure-aws-sso aws-login aws-whoami

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init-config: ## Create config.env from config.example.env
	@bash scripts/local/init-config.sh

doctor: ## Check local config and required CLI tools
	@bash scripts/local/doctor.sh

configure-aws-sso: ## Generate the AWS CLI SSO profile from config.env
	@bash scripts/local/configure-aws-sso.sh

aws-login: ## Log in to AWS SSO using the configured profile
	@bash scripts/local/aws-login.sh

aws-whoami: ## Show the current AWS CLI identity
	@bash scripts/local/aws-whoami.sh

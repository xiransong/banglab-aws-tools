SHELL := /bin/bash

.PHONY: help init-config doctor configure-aws-sso aws-login aws-whoami ssh-status create-key import-key create-security-group add-ssh-rule

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "%-26s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

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

ssh-status: ## Show SSH key pair and security group setup status
	@bash scripts/ssh/ssh-status.sh

create-key: ## Create the local SSH key pair
	@bash scripts/ssh/create-key.sh

import-key: ## Import the public SSH key to AWS as an owner-tagged key pair
	@bash scripts/ssh/import-key.sh

create-security-group: ## Create the owner-tagged SSH security group
	@bash scripts/ssh/create-security-group.sh

add-ssh-rule: ## Add an SSH ingress rule for the current IP, e.g. make add-ssh-rule SSH_RULE_NAME=home
	@SSH_RULE_NAME="$(SSH_RULE_NAME)" bash scripts/ssh/add-ssh-rule.sh

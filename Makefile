SHELL := /bin/bash

.PHONY: help init-config doctor configure-aws-sso aws-login aws-whoami ssh-status create-key import-key create-security-group add-ssh-rule instances launch-instance instance-status configure-ssh stop-instance start-instance reboot-instance terminate-instance volumes create-volume attach-volume setup-scratch mount-scratch save-dotfiles restore-dotfiles

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

instances: ## List EC2 instances owned by the configured user
	@bash scripts/ec2/instances.sh

launch-instance: ## Launch an EC2 instance, e.g. make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
	@INSTANCE_NAME="$(INSTANCE_NAME)" INSTANCE_CONFIG="$(INSTANCE_CONFIG)" AMI_ID="$(AMI_ID)" INSTANCE_TYPE="$(INSTANCE_TYPE)" ROOT_VOLUME_SIZE_GB="$(ROOT_VOLUME_SIZE_GB)" bash scripts/ec2/launch-instance.sh

instance-status: ## Show EC2 instance status, e.g. make instance-status INSTANCE_NAME=dev
	@INSTANCE_NAME="$(INSTANCE_NAME)" bash scripts/ec2/instance-status.sh

configure-ssh: ## Update ~/.ssh/config for an EC2 instance, e.g. make configure-ssh INSTANCE_NAME=dev SSH_HOST=ec2
	@INSTANCE_NAME="$(INSTANCE_NAME)" SSH_HOST="$(SSH_HOST)" bash scripts/ec2/configure-ssh.sh

stop-instance: ## Stop an EC2 instance, e.g. make stop-instance INSTANCE_NAME=dev
	@INSTANCE_NAME="$(INSTANCE_NAME)" bash scripts/ec2/stop-instance.sh

start-instance: ## Start an EC2 instance, e.g. make start-instance INSTANCE_NAME=dev
	@INSTANCE_NAME="$(INSTANCE_NAME)" bash scripts/ec2/start-instance.sh

reboot-instance: ## Reboot a running EC2 instance, e.g. make reboot-instance INSTANCE_NAME=dev
	@INSTANCE_NAME="$(INSTANCE_NAME)" bash scripts/ec2/reboot-instance.sh

terminate-instance: ## Terminate an EC2 instance, e.g. make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
	@INSTANCE_NAME="$(INSTANCE_NAME)" CONFIRM_TERMINATE="$(CONFIRM_TERMINATE)" bash scripts/ec2/terminate-instance.sh

volumes: ## List EBS volumes owned by the configured user
	@bash scripts/ebs/volumes.sh

create-volume: ## Create a persistent EBS volume, e.g. make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
	@VOLUME_NAME="$(VOLUME_NAME)" VOLUME_SIZE_GB="$(VOLUME_SIZE_GB)" bash scripts/ebs/create-volume.sh

attach-volume: ## Attach a persistent EBS volume, e.g. make attach-volume VOLUME_ID=vol-... INSTANCE_NAME=dev
	@VOLUME_ID="$(VOLUME_ID)" INSTANCE_NAME="$(INSTANCE_NAME)" bash scripts/ebs/attach-volume.sh

setup-scratch: ## Inside EC2: format and mount a new scratch EBS volume
	@VOLUME_ID="$(VOLUME_ID)" CONFIRM_SETUP_SCRATCH="$(CONFIRM_SETUP_SCRATCH)" bash scripts/remote/setup-scratch.sh

mount-scratch: ## Inside EC2: mount an initialized scratch EBS volume
	@VOLUME_ID="$(VOLUME_ID)" bash scripts/remote/mount-scratch.sh

save-dotfiles: ## Inside EC2: save selected dotfiles to persistent EBS
	@bash scripts/remote/save-dotfiles.sh

restore-dotfiles: ## Inside EC2: restore selected dotfiles from persistent EBS
	@bash scripts/remote/restore-dotfiles.sh

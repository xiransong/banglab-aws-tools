# Loop 2 API: SSH Access Setup

This document defines the command interface for Loop 2 before implementation.

## User Commands

All user-facing commands are Make targets run from the repo root.

```bash
make ssh-status
make create-key
make import-key
make create-security-group
make add-ssh-rule SSH_RULE_NAME=home
```

## Config Additions

Loop 2 adds these values to `config.example.env`:

```bash
SSH_KEY_PATH=${HOME}/.ssh/${OWNER}
KEY_NAME=${OWNER}-key
SECURITY_GROUP_NAME=${OWNER}-ssh
SSH_PORT=22
```

`SSH_RULE_NAME` is not stored in config. It is passed at command time.

## `make ssh-status`

Purpose: show SSH setup state.

Inputs:

- `config.env`
- AWS CLI profile from Loop 1

Checks:

- local private key exists at `SSH_KEY_PATH`
- local public key exists at `${SSH_KEY_PATH}.pub`
- AWS key pair exists as `KEY_NAME`
- AWS key pair has `Owner=${OWNER}`
- default VPC exists
- security group exists as `SECURITY_GROUP_NAME`
- security group has `Owner=${OWNER}`
- SSH inbound rules on the security group

Expected behavior:

- prints a readable status summary
- does not create, modify, or delete resources

## `make create-key`

Purpose: create a local SSH key pair.

Inputs:

- `config.env`
- `SSH_KEY_PATH`

Expected behavior:

- creates an ed25519 key pair at:
  - `SSH_KEY_PATH`
  - `${SSH_KEY_PATH}.pub`
- creates the parent `~/.ssh` directory if needed
- sets safe file permissions
- refuses to overwrite existing key files

## `make import-key`

Purpose: import the local public key to AWS.

Inputs:

- `config.env`
- `${SSH_KEY_PATH}.pub`
- `KEY_NAME`

Expected behavior:

- imports `${SSH_KEY_PATH}.pub` as `KEY_NAME`
- applies tags:
  - `Owner=${OWNER}`
  - `Name=${KEY_NAME}`
- if the AWS key pair already exists, verifies `Owner=${OWNER}`, prints OK, and
  does nothing
- if tagged import fails because of authorization, exits with a clear message to
  check that the active AWS CLI profile is using the updated permission set

Planned AWS command shape:

```bash
aws ec2 import-key-pair \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --key-name "${KEY_NAME}" \
  --public-key-material "fileb://${SSH_KEY_PATH}.pub" \
  --tag-specifications "ResourceType=key-pair,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${KEY_NAME}}]"
```

## `make create-security-group`

Purpose: create an owner-tagged SSH security group.

Inputs:

- `config.env`
- default VPC
- `SECURITY_GROUP_NAME`

Expected behavior:

- discovers the default VPC
- creates `SECURITY_GROUP_NAME` in the default VPC
- applies tags:
  - `Owner=${OWNER}`
  - `Name=${SECURITY_GROUP_NAME}`
- if the security group already exists, prints OK and does nothing
- fails clearly if no default VPC exists

Planned AWS command shape:

```bash
aws ec2 create-security-group \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --vpc-id "${DEFAULT_VPC_ID}" \
  --group-name "${SECURITY_GROUP_NAME}" \
  --description "SSH access for ${OWNER}" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${SECURITY_GROUP_NAME}}]"
```

## `make add-ssh-rule SSH_RULE_NAME=home`

Purpose: allow SSH from the current public IP.

Inputs:

- `config.env`
- `SSH_RULE_NAME`
- current public IP from `https://checkip.amazonaws.com`
- owner-tagged security group

Expected behavior:

- requires `SSH_RULE_NAME`
- discovers the security group ID
- detects current public IP
- adds TCP ingress for `SSH_PORT` from `<current-ip>/32`
- uses description `${OWNER}-${SSH_RULE_NAME}`
- if the exact rule already exists, prints OK and does nothing
- does not revoke old rules

Planned AWS command shape:

```bash
aws ec2 authorize-security-group-ingress \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --group-id "${SECURITY_GROUP_ID}" \
  --ip-permissions "IpProtocol=tcp,FromPort=${SSH_PORT},ToPort=${SSH_PORT},IpRanges=[{CidrIp=${CURRENT_IP}/32,Description=${OWNER}-${SSH_RULE_NAME}}]"
```

## Script Mapping

```text
make ssh-status            -> scripts/ssh/ssh-status.sh
make create-key            -> scripts/ssh/create-key.sh
make import-key            -> scripts/ssh/import-key.sh
make create-security-group -> scripts/ssh/create-security-group.sh
make add-ssh-rule          -> scripts/ssh/add-ssh-rule.sh
```

Shared helpers:

```text
scripts/lib/aws.sh
scripts/lib/config.sh
scripts/lib/log.sh
scripts/lib/checks.sh
```

## Policy Note

The current `EC2-GPU-Operator` permission set enforces owner tags for both key
pairs and security groups. Key-pair creation/import requires `Owner=${OWNER}` at
creation time, and key-pair deletion is limited to resources with the matching
`Owner` tag.

Security group creation is authorized against both the new security group and
the target VPC. The policy therefore needs a tag-scoped
`ec2:CreateSecurityGroup` allowance for `security-group/*` plus a VPC allowance
for `vpc/*`.

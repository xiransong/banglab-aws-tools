# Loop 1 API: Local Machine Setup

This document defines the command interface for Loop 1 before implementation.

## User Commands

All user-facing commands are Make targets run from the repo root.

```bash
make help
make init-config
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
```

## Config File

The user config file is:

```text
config.env
```

It is created from:

```text
config.example.env
```

`config.env` must not be committed.

Required variables for Loop 1:

```bash
OWNER=takishiina
AWS_PROFILE=takishiina
AWS_REGION=us-east-1
AWS_ACCOUNT_LABEL=xiransong
AWS_ACCOUNT_ID=777712053059
AWS_SSO_START_URL=https://banglab-udem-mila.awsapps.com/start
AWS_SSO_REGION=us-east-1
AWS_SSO_ROLE_NAME=EC2-GPU-Operator
AWS_SSO_SESSION=banglab
```

Optional/default variable:

```bash
DEFAULT_AVAILABILITY_ZONE=us-east-1a
```

## `make help`

Purpose: show available commands.

Inputs: none.

Expected behavior:

- prints the Make targets with short descriptions
- does not require `config.env`

## `make init-config`

Purpose: create local config.

Inputs:

- `config.example.env`

Expected behavior:

- creates `config.env` if it does not exist
- refuses to overwrite an existing `config.env`
- prints a safe config summary
- prints a highlighted action prompt telling the user to edit user-specific
  fields before continuing

## `make doctor`

Purpose: check local readiness.

Inputs:

- `config.env`

Checks:

- `config.env` exists
- required config variables are set
- AWS CLI is installed
- AWS CLI is version 2
- `make`, `git`, `ssh`, `curl`, and `jq` are installed

Expected behavior:

- prints pass/fail status for each check
- prints a safe config summary
- does not run AWS login
- does not call AWS STS
- does not create or modify AWS resources

## `make configure-aws-sso`

Purpose: generate AWS CLI SSO profile.

Inputs:

- `config.env`
- existing `~/.aws/config`, if present

Expected behavior:

- ensures `~/.aws` exists
- creates `~/.aws/config` if missing
- makes a timestamped backup if `~/.aws/config` already exists
- removes existing sections matching:
  - `[profile ${AWS_PROFILE}]`
  - `[sso-session ${AWS_SSO_SESSION}]`
- appends generated profile and SSO session sections
- does not perform browser login

Generated profile shape:

```ini
[profile takishiina]
sso_session = banglab
sso_account_id = 777712053059
sso_role_name = EC2-GPU-Operator
region = us-east-1
output = json

[sso-session banglab]
sso_start_url = https://banglab-udem-mila.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

## `make aws-login`

Purpose: authenticate with AWS SSO.

Inputs:

- `config.env`
- configured AWS profile

Expected behavior:

- runs `aws sso login --profile "${AWS_PROFILE}"`
- opens browser login/MFA through AWS CLI

## `make aws-whoami`

Purpose: verify AWS CLI identity.

Inputs:

- `config.env`
- authenticated AWS SSO profile

Expected behavior:

- runs `aws sts get-caller-identity --profile "${AWS_PROFILE}"`
- prints the returned identity JSON

## Script Mapping

```text
make init-config       -> scripts/local/init-config.sh
make doctor            -> scripts/local/doctor.sh
make configure-aws-sso -> scripts/local/configure-aws-sso.sh
make aws-login         -> scripts/local/aws-login.sh
make aws-whoami        -> scripts/local/aws-whoami.sh
```

Shared helpers:

```text
scripts/lib/config.sh
scripts/lib/log.sh
scripts/lib/checks.sh
```

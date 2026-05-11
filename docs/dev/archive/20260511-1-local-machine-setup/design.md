# Loop 1 Design: Local Machine Setup

Started: 2026-05-11

## Goal

Design the first usable slice of `banglab-aws-tools`: local laptop readiness.

This loop should help a lab member verify that their local machine can talk to
AWS through the CLI before they create EC2 instances, EBS volumes, or other AWS
resources.

The first test user is:

```text
Name: Taki Shiina
Username / Owner: takishiina
Permission set: EC2-GPU-Operator
AWS account used for testing: xiransong account
```

## Prerequisite Boundary

AWS Access Portal Login is a prerequisite for this toolbox.

Before using `banglab-aws-tools`, the user should already be able to:

- log in to the BangLab AWS Access Portal
- complete MFA
- select an AWS account
- select the `EC2-GPU-Operator` permission set
- open the AWS Console

This loop starts after that point.

## Local Machine Assumptions

Supported in the first version:

- macOS Terminal or iTerm
- Linux shell
- Windows via WSL2 Ubuntu

Not supported in the first version:

- native Windows PowerShell
- native Windows CMD

The toolbox assumes a Unix-like terminal with common command-line tools.

## Required Local Tools

The toolbox should verify these tools, not install them:

- AWS CLI v2
- `make`
- `git`
- `ssh`
- `curl`
- `jq`

AWS CLI installation should be documented as a prerequisite. The toolbox should
begin by checking whether `aws --version` reports AWS CLI v2.

## User-Facing Docs To Design

This loop should draft and later promote:

```text
docs/prerequisites.md
docs/local-machine-setup.md
```

### `docs/prerequisites.md`

Purpose: answer "Am I ready to use this repo?"

It should cover:

- AWS Access Portal Login completed
- supported terminal environments
- AWS CLI v2 installed
- required CLI tools installed
- user knows their BangLab username / `Owner` value
- user knows the AWS account and permission set to use

### `docs/local-machine-setup.md`

Purpose: guide the first machine-level setup after prerequisites are satisfied.

It should cover:

- create `config.env` from `config.example.env`
- fill in `OWNER`, `AWS_PROFILE`, `AWS_ACCOUNT_ID`, `AWS_ACCOUNT_LABEL`, and
  `AWS_REGION`
- run `make doctor`
- configure AWS SSO profile with `make configure-aws-sso`
- run `make aws-login`
- run `make aws-whoami`

## Planned Repo Structure For This Loop

```text
banglab-aws-tools/
├── Makefile
├── config.example.env
├── .gitignore
├── docs/
│   ├── prerequisites.md
│   └── local-machine-setup.md
└── scripts/
    ├── lib/
    │   ├── config.sh
    │   ├── log.sh
    │   └── checks.sh
    └── local/
        ├── init-config.sh
        ├── configure-aws-sso.sh
        ├── doctor.sh
        ├── aws-login.sh
        └── aws-whoami.sh
```

The `Makefile` should be the user-facing command menu. Scripts should contain
the real logic.

## Proposed Make Targets

```bash
make help
make init-config
make configure-aws-sso
make doctor
make aws-login
make aws-whoami
```

Target behavior:

- `make help`: show available commands
- `make init-config`: create `config.env` from `config.example.env`, refusing
  to overwrite an existing file
- `make configure-aws-sso`: create or update the AWS CLI SSO profile in
  `~/.aws/config` using values from `config.env`
- `make doctor`: simple local readiness check for config and required tools
- `make aws-login`: run AWS SSO login for the configured profile
- `make aws-whoami`: show the current AWS identity for the configured profile

Boundary for `make doctor`:

- It should stay simple in Loop 1.
- It should check that `config.env` exists.
- It should check required config variables.
- It should check required local tools.
- It may print a reminder to run `make aws-login` and `make aws-whoami`.
- It should not try to create AWS profiles, log in, or provision AWS resources.

## Proposed Config Variables

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
DEFAULT_AVAILABILITY_ZONE=us-east-1a
```

Required in Loop 1:

- `OWNER`
- `AWS_PROFILE`
- `AWS_REGION`
- `AWS_ACCOUNT_LABEL`
- `AWS_ACCOUNT_ID`
- `AWS_SSO_START_URL`
- `AWS_SSO_REGION`
- `AWS_SSO_ROLE_NAME`
- `AWS_SSO_SESSION`

Future loops can add EC2, EBS, S3, and optional-tool variables.

Important distinction:

```text
OWNER=takishiina
AWS_ACCOUNT_LABEL=xiransong
AWS_ACCOUNT_ID=777712053059
```

`OWNER` controls resource ownership tags. `AWS_ACCOUNT_LABEL` is only a human
label for the selected AWS account. `AWS_ACCOUNT_ID` is the 12-digit account ID
required by the AWS CLI SSO profile.

The user can copy the account ID from the AWS Access Portal.

## AWS SSO Configuration Design

The toolbox should be self-contained and should not require users to run the
full interactive `aws configure sso` flow.

Instead, `make configure-aws-sso` should write an AWS CLI profile like:

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

The browser login/MFA step still happens through:

```bash
make aws-login
```

## Out Of Scope For This Loop

- creating SSH key pairs
- importing SSH keys to AWS
- creating security groups
- creating or formatting EBS volumes
- launching EC2 instances
- S3 workflows
- GitHub setup
- micromamba setup
- Node.js or Codex setup

Those belong to later loops.

## Done Criteria

This loop is done when:

- prerequisites and local setup docs are drafted and reviewed
- command/API shape is documented
- `Makefile`, `config.example.env`, and local setup scripts are implemented
- `make doctor`, `make aws-login`, and `make aws-whoami` work for the test
  profile
- `status_and_plan.md` is updated
- loop docs are archived or promoted according to `docs/dev/README.md`

## Open Questions

Resolved:

- `make doctor` should stay simple and should not perform AWS login or identity
  calls in Loop 1.
- `AWS_ACCOUNT_LABEL` is required because it helps configure and identify the
  intended AWS SSO profile/account context.
- `AWS_ACCOUNT_ID` is required because the generated AWS CLI SSO profile needs
  the 12-digit account ID.
- `jq` is required in Loop 1. It is a small useful CLI tool and will be needed
  by later AWS status and resource scripts.
- `banglab-aws-tools` should be self-contained for AWS CLI SSO setup. It should
  guide the user to copy the AWS account ID from the AWS Access Portal and then
  generate the AWS CLI profile with `make configure-aws-sso`.
- `configure-aws-sso` should make a timestamped backup of the AWS config file,
  remove matching profile/session sections, and append the generated sections.

Open: none for Loop 1 design.

## Loop Todo

1. Draft user-facing docs: done
   - `docs/prerequisites.md`
   - `docs/local-machine-setup.md`

2. Draft command/API docs: done
   - Create `docs/dev/loop/api.md`.
   - Specify Make targets, script inputs, config variables, and expected output.

3. Add config files: done
   - Add `.gitignore` for `config.env`.
   - Add `config.example.env`.

4. Add Makefile: done
   - Add `make help`.
   - Add local setup targets.

5. Implement local setup scripts: done
   - `scripts/local/init-config.sh`
   - `scripts/local/configure-aws-sso.sh`
   - `scripts/local/doctor.sh`
   - `scripts/local/aws-login.sh`
   - `scripts/local/aws-whoami.sh`
   - shared helpers under `scripts/lib/`

6. Verify with test user assumptions: in progress
   - Use `OWNER=takishiina`.
   - Use `AWS_PROFILE=takishiina`.
   - Use the `xiransong` AWS account ID copied from AWS Access Portal.
   - Confirm `make doctor`, `make configure-aws-sso`, `make aws-login`, and
     `make aws-whoami` behave as expected.

7. Close the loop
   - Update `docs/dev/status_and_plan.md`.
   - Promote stable docs.
   - Archive loop docs according to `docs/dev/README.md`.

# Status And Plan

Last updated: 2026-05-11

This file is the development cockpit for `banglab-aws-tools`. Read this first
when returning to the repo.

## Current Repo Status

The repo has completed Loop 1: Local Machine Setup and Loop 2: SSH Access
Setup.

Current stable files:

- `README.md`: brief repo-level framing
- `docs/README.md`: user-facing docs index
- `docs/prerequisites.md`: prerequisite checklist for using the toolbox
- `docs/local-machine-setup.md`: local setup workflow for Loop 1
- `docs/ssh-access-setup.md`: SSH key pair and security group workflow for
  Loop 2
- `scripts/README.md`: overview of implemented script structure
- `docs/dev/README.md`: development rules and loop process
- `docs/dev/status_and_plan.md`: this cockpit file

Loop 1 local setup scripts have been implemented and verified. Loop 2 SSH key
pair and security group setup scripts have also been implemented and verified
with the `takishiina` test profile. The AWS `EC2-GPU-Operator` permission set
now enforces owner tags for both key pairs and security groups.

## Active Loop

Active loop:

```text
None
```

Current state:

```text
No active loop. Ready to choose the next workflow area.
```

Active loop docs:

```text
None
```

## Completed Loops

```text
docs/dev/archive/20260511-1-local-machine-setup
docs/dev/archive/20260511-2-ssh-access-setup
```

Completed loops:

```text
Loop 1: Local Machine Setup
Loop 2: SSH Access Setup
```

Implemented commands:

```text
make help
make init-config
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
make ssh-status
make create-key
make import-key
make create-security-group
make add-ssh-rule SSH_RULE_NAME=home
```

## Decisions So Far

- Development is documentation-first: draft workflow and command/API docs before
  implementation.
- `docs/dev` is for plans, designs, API drafts, and implementation logs.
- At most one active loop may exist at a time.
- Active loop docs live in `docs/dev/loop`.
- Closed loop docs move to `docs/dev/archive/YYYYMMDD-N-short-name`.
- User-facing docs outside `docs/dev` should stay stable during a loop.
- AWS Access Portal Login is a prerequisite, not part of this toolbox.
- The toolbox starts after a user can log in through AWS Access Portal and
  select `EC2-GPU-Operator`.
- `AWS_ACCOUNT_LABEL` is required in local config so users can identify the AWS
  account context used by their SSO profile.
- `jq` is required as a standard local CLI dependency.
- `make doctor` should stay simple in Loop 1: check local config and tools, but
  do not log in or call AWS identity APIs.
- Persistent EBS should be mounted at `~/scratch`, not directly at `~/`.
- The repo should be an easy-to-use toolbox for research workflows, likely with
  a `Makefile` as the main command interface.
- SSH access setup uses local ed25519 keys at `SSH_KEY_PATH`, AWS key pairs
  named `<OWNER>-key`, and security groups named `<OWNER>-ssh`.
- SSH inbound rules are named by location with descriptions such as
  `<OWNER>-home`.
- Loop 2 uses the default VPC. Custom VPC support is future work.
- `EC2-GPU-Operator` authorizes `CreateSecurityGroup` against both the new
  security group and the target VPC, so the policy includes a VPC-side
  allowance for that action.

## Planned Workflow Areas

- Local Machine Setup
- Status checks for EC2 instances and EBS volumes
- One-time AWS resource setup
- Persistent EBS initialization
- Daily EC2/EBS workflow
- Optional research tooling: GitHub, micromamba, Node.js, Codex
- Safety and cleanup commands: stop, start, terminate, detach

## Short-Term Plan

1. Choose Loop 3.
2. Draft Loop 3 design in `docs/dev/loop/design.md`.
3. Draft command/API docs before implementation.

Loop 1 was tested with:

```text
Name: Taki Shiina
Username / Owner: takishiina
Permission set: EC2-GPU-Operator
AWS account: xiransong
AWS account ID: 777712053059
```

Loop 2 was tested with the same profile. The successful AWS resources were:

```text
AWS key pair: takishiina-key
Security group: takishiina-ssh (sg-0970ff24473e84a81)
SSH rule: 142.120.164.249/32, takishiina-home
```

## Next Concrete Step

Choose the next loop. Good candidates:

```text
EC2 instance status checks
Instance type selection
Launch/stop/terminate workflow
Persistent EBS setup
```

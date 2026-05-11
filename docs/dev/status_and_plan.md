# Status And Plan

Last updated: 2026-05-11

This file is the development cockpit for `banglab-aws-tools`. Read this first
when returning to the repo.

## Current Repo Status

The repo has completed Loop 1: Local Machine Setup.

Current stable files:

- `README.md`: brief repo-level framing
- `docs/README.md`: user-facing docs index
- `docs/prerequisites.md`: prerequisite checklist for using the toolbox
- `docs/local-machine-setup.md`: local setup workflow for Loop 1
- `scripts/README.md`: overview of implemented script structure
- `docs/dev/README.md`: development rules and loop process
- `docs/dev/status_and_plan.md`: this cockpit file

Loop 1 local setup scripts have been implemented and verified. AWS resource
workflow scripts have not been implemented yet.

## Active Loop

There is currently no active loop.

## Completed Loops

```text
docs/dev/archive/20260511-1-local-machine-setup
```

Completed Loop 1:

```text
Local Machine Setup
```

Implemented commands:

```text
make help
make init-config
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
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

## Planned Workflow Areas

- Local Machine Setup
- Status checks for EC2 instances and EBS volumes
- One-time AWS resource setup
- Persistent EBS initialization
- Daily EC2/EBS workflow
- Optional research tooling: GitHub, micromamba, Node.js, Codex
- Safety and cleanup commands: stop, start, terminate, detach

## Short-Term Plan

1. Keep Loop 1 stable unless a user-facing issue appears.
2. Choose the next active loop.
3. Likely next loop candidates:
   - status checks for EC2 instances and EBS volumes
   - SSH key pair and security group setup
   - persistent EBS creation

Loop 1 was tested with:

```text
Name: Taki Shiina
Username / Owner: takishiina
Permission set: EC2-GPU-Operator
AWS account: xiransong
AWS account ID: 777712053059
```

## Next Concrete Step

Start the next loop by creating:

```text
docs/dev/loop/design.md
```

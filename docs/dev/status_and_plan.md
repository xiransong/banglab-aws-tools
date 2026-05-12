# Status And Plan

Last updated: 2026-05-12

This file is the development cockpit for `banglab-aws-tools`. Read this first
when returning to the repo.

## Current Repo Status

The repo has completed Loop 1: Local Machine Setup, Loop 2: SSH Access Setup,
and Loop 3: EC2 Instance Lifecycle.

Current stable files:

- `README.md`: brief repo-level framing
- `docs/README.md`: user-facing docs index
- `docs/prerequisites.md`: prerequisite checklist for using the toolbox
- `docs/local-machine-setup.md`: local setup workflow for Loop 1
- `docs/ssh-access-setup.md`: SSH key pair and security group workflow for
  Loop 2
- `docs/ec2-instance-lifecycle.md`: EC2 launch, SSH config, status, and
  lifecycle workflow for Loop 3
- `scripts/README.md`: overview of implemented script structure
- `docs/dev/README.md`: development rules and loop process
- `docs/dev/status_and_plan.md`: this cockpit file

Loop 1 local setup scripts have been implemented and verified. Loop 2 SSH key
pair and security group setup scripts have also been implemented and verified
with the `takishiina` test profile. Loop 3 EC2 instance lifecycle design,
user-facing docs, command/API docs, instance recipes, Make targets, and scripts
have been implemented. All Loop 3 commands were verified with the `takishiina`
test profile. Loop 4 Persistent EBS Management design, user-facing docs,
command/API docs, Make targets, and scripts have been drafted/implemented. The
AWS `EC2-GPU-Operator` permission set now enforces owner tags for key pairs,
security groups, and EC2 instance launch workflows.

## Active Loop

Active loop:

```text
Loop 4: Persistent EBS Management
```

Current state:

```text
Implemented; awaiting manual AWS and inside-instance verification
```

Active loop docs:

```text
docs/dev/loop/design.md
docs/dev/loop/api.md
docs/dev/loop/implementation_log.md
docs/dev/loop/review_checklist.md
```

## Completed Loops

```text
docs/dev/archive/20260511-1-local-machine-setup
docs/dev/archive/20260511-2-ssh-access-setup
docs/dev/archive/20260512-3-ec2-instance-lifecycle
```

Completed loops:

```text
Loop 1: Local Machine Setup
Loop 2: SSH Access Setup
Loop 3: EC2 Instance Lifecycle
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
make instances
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make instance-status INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev
make stop-instance INSTANCE_NAME=dev
make start-instance INSTANCE_NAME=dev
make reboot-instance INSTANCE_NAME=dev
make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
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
- `AWS_SSO_SESSION` should be unique per AWS user on the same laptop, for
  example `banglab-takishiina`. Otherwise AWS CLI can reuse an SSO token from a
  different local profile.
- `make aws-whoami` checks that the STS account, role, and final assumed-role
  session name match `config.env`.
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
- EC2 launch uses explicit instance recipe files under `instances/`.
- Loop 3 includes two starter recipes: `m7i-flex.xlarge` and `g4dn.xlarge`,
  both using AMI `ami-0252d9c82e6b8fa85` and a 200 GB root volume.
- `make launch-instance` waits until the instance reaches `running`.
- SSH may still need 30-60 seconds after EC2 reports `running`; users should
  retry if the first SSH attempt says `Connection refused`.
- `make configure-ssh` manages a marked `~/.ssh/config` block and defaults to
  `SSH_HOST=ec2`.
- `make instances` uses compact per-instance blocks rather than a wide table.
- `make start-instance` tolerates a brief stale `stopped` state after AWS
  accepts the start request.
- `EC2-GPU-Operator` `RunInstances` permissions must be split across created
  resources, owned launch dependencies, and untagged launch dependencies.

## Planned Workflow Areas

- Local Machine Setup
- Status checks for EC2 instances and EBS volumes
- One-time AWS resource setup
- Persistent EBS initialization
- Daily EC2/EBS workflow
- Optional research tooling: GitHub, micromamba, Node.js, Codex
- Safety and cleanup commands: stop, start, terminate, detach

## Short-Term Plan

1. Review Loop 4 implementation.
2. Manually verify local EBS AWS commands with the `takishiina` profile.
3. Manually verify inside-instance scratch setup/mount.

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

Loop 3 was tested with the same profile. The successful AWS resources were:

```text
Instance name: dev
Instance ID: i-0a2d33a07be6c6cf0
Instance type: m7i-flex.xlarge
Public IP: 44.202.207.72
SSH host: ec2
```

## Next Concrete Step

Review and manually verify Loop 4:

```text
docs/dev/loop/design.md
docs/dev/loop/api.md
docs/persistent-ebs.md
make volumes
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
make attach-volume VOLUME_ID=vol-... INSTANCE_NAME=dev
make setup-scratch VOLUME_ID=vol-... CONFIRM_SETUP_SCRATCH=YES
make mount-scratch VOLUME_ID=vol-...
```

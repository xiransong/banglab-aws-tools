# Loop 2 Design: SSH Access Setup

Started: 2026-05-11

## Goal

Design the SSH access setup workflow for `banglab-aws-tools`.

This loop prepares a user's local SSH key pair and AWS security group so later
EC2 launch workflows can assume:

```text
AWS key pair: <OWNER>-key
Security group: <OWNER>-ssh
SSH port: 22
Key pair tags: Owner=<OWNER>, Name=<OWNER>-key
Security group tags: Owner=<OWNER>, Name=<OWNER>-ssh
```

This loop does not launch EC2 instances.

## Prerequisites

The user should have completed Loop 1 local machine setup:

```bash
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
```

The user should have a working `config.env`.

Test user:

```text
Name: Taki Shiina
Username / Owner: takishiina
Permission set: EC2-GPU-Operator
AWS account: xiransong
AWS account ID: 777712053059
```

## Policy Constraints

The `EC2-GPU-Operator` permission set allows:

- EC2 read-only describe actions
- key pair management:
  - `ec2:DescribeKeyPairs`
  - `ec2:CreateKeyPair` and `ec2:ImportKeyPair` only when the request includes
    the user's own `Owner` tag
  - `ec2:CreateTags` for key pairs only during key-pair creation/import
  - `ec2:DeleteKeyPair` only for key pairs with the user's own `Owner` resource
    tag
- security group creation only with request tags:
  - `Owner=<username>`
  - `Name=<username>-ssh`
- VPC use during security group creation, because `ec2:CreateSecurityGroup` is
  authorized against both the new security group and the target VPC
- security group management only when the security group has the matching
  `Owner` resource tag

The toolbox must create or import key pairs with `Owner` and `Name` tags.
Key pairs are now fully owner-tag-scoped in the `EC2-GPU-Operator` permission
set. Security groups are also owner-tag-scoped.

## User-Facing Docs To Design

This loop should draft and later promote:

```text
docs/ssh-access-setup.md
```

The doc should cover:

- what an SSH key pair is
- what a security group is
- why names use the `OWNER` value
- why key pairs and security groups are tagged with `Owner` and `Name`
- how to check current SSH setup status
- how to create a local SSH key
- how to import the public key to AWS
- how to create an owner-tagged security group
- how to add named SSH inbound rules for places such as `home` or `lab`
- what later EC2 workflows will use

## Planned Config Additions

Add these defaults to `config.example.env`:

```bash
SSH_KEY_PATH=${HOME}/.ssh/${OWNER}
KEY_NAME=${OWNER}-key
SECURITY_GROUP_NAME=${OWNER}-ssh
SSH_PORT=22
```

Do not put `SSH_RULE_NAME` in config. It should be passed at command time so a
user can add multiple named locations.

## Planned Repo Structure For This Loop

```text
banglab-aws-tools/
├── docs/
│   └── ssh-access-setup.md
└── scripts/
    ├── lib/
    │   └── aws.sh
    └── ssh/
        ├── ssh-status.sh
        ├── create-key.sh
        ├── import-key.sh
        ├── create-security-group.sh
        └── add-ssh-rule.sh
```

Existing shared helpers in `scripts/lib/` should be reused where possible.

## Proposed Make Targets

```bash
make ssh-status
make create-key
make import-key
make create-security-group
make add-ssh-rule SSH_RULE_NAME=home
```

Target behavior:

- `make ssh-status`: show local and AWS SSH setup state
- `make create-key`: create local ed25519 SSH key at `SSH_KEY_PATH`
- `make import-key`: import `${SSH_KEY_PATH}.pub` into AWS as `KEY_NAME` with
  `Owner` and `Name` tags; if the key pair already exists, verify its `Owner`
  tag
- `make create-security-group`: create `SECURITY_GROUP_NAME` in the default VPC
  with `Owner` and `Name` tags
- `make add-ssh-rule SSH_RULE_NAME=home`: authorize SSH from the current public
  IP with rule description `${OWNER}-${SSH_RULE_NAME}`

## Default VPC Decision

Loop 2 should use the default VPC.

The script should discover it with:

```bash
aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true
```

If no default VPC exists, the script should fail with a clear message.

Custom VPC support is out of scope for Loop 2.

## SSH Rule Naming

Users may connect from multiple places, and public IPs may change.

Therefore, SSH inbound rules should be named by location:

```bash
make add-ssh-rule SSH_RULE_NAME=home
make add-ssh-rule SSH_RULE_NAME=lab
```

The rule description should be:

```text
<OWNER>-<SSH_RULE_NAME>
```

Example:

```text
takishiina-home
takishiina-lab
```

Loop 2 should add the current IP as a `/32` CIDR:

```text
<current-public-ip>/32
```

If the exact rule already exists, the command should print OK and do nothing.

Loop 2 should not revoke old rules automatically.

## Out Of Scope For This Loop

- EC2 instance launch
- EBS volume creation or mounting
- S3 workflows
- deleting key pairs
- deleting security groups
- revoking old SSH rules
- custom VPC support
- GitHub, micromamba, Node.js, or Codex setup

## Done Criteria

This loop is done when:

- `docs/ssh-access-setup.md` is drafted and reviewed
- command/API shape is documented
- config additions are implemented
- Make targets are implemented
- SSH scripts are implemented
- commands work with the Taki test profile
- `status_and_plan.md` is updated
- loop docs are archived according to `docs/dev/README.md`

## Loop Todo

1. Draft user-facing docs: done
   - `docs/ssh-access-setup.md`

2. Draft command/API docs: done
   - `docs/dev/loop/api.md`

3. Add config defaults: done
   - `SSH_KEY_PATH`
   - `KEY_NAME`
   - `SECURITY_GROUP_NAME`
   - `SSH_PORT`

4. Add Make targets: done
   - `ssh-status`
   - `create-key`
   - `import-key`
   - `create-security-group`
   - `add-ssh-rule`

5. Implement SSH setup scripts: done
   - local key creation
   - owner-tagged AWS key pair import
   - default VPC lookup
   - owner-tagged security group creation
   - named SSH ingress rule creation

6. Verify with test user assumptions
   - `OWNER=takishiina`
   - `AWS_PROFILE=takishiina`
   - `KEY_NAME=takishiina-key`
   - `SECURITY_GROUP_NAME=takishiina-ssh`

7. Close the loop
   - update `docs/dev/status_and_plan.md`
   - archive loop docs

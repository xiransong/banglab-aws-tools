# Loop 2 Implementation Log

## 2026-05-11

Implemented SSH access setup scripts for local key pairs, AWS key pair import,
owner-tagged security group creation, and named SSH inbound rules.

Added config defaults:

- `SSH_KEY_PATH`
- `KEY_NAME`
- `SECURITY_GROUP_NAME`
- `SSH_PORT`

Added Make targets:

- `make ssh-status`
- `make create-key`
- `make import-key`
- `make create-security-group`
- `make add-ssh-rule SSH_RULE_NAME=home`

Added shared AWS helper:

- `scripts/lib/aws.sh`

Added SSH scripts:

- `scripts/ssh/ssh-status.sh`
- `scripts/ssh/create-key.sh`
- `scripts/ssh/import-key.sh`
- `scripts/ssh/create-security-group.sh`
- `scripts/ssh/add-ssh-rule.sh`

Implementation notes:

- `create-key` creates an ed25519 key and refuses to overwrite existing key
  files.
- `import-key` imports the public key with `Owner` and `Name` tags.
- `import-key` checks the `Owner` tag if the AWS key pair already exists.
- `import-key` does not silently fall back to an untagged key pair.
- `ssh-status` reports owner-tag status for the AWS key pair and security group.
- `create-security-group` uses the default VPC and owner tags.
- `add-ssh-rule` adds the current public IP as a `/32` ingress rule with a
  description such as `takishiina-home`.
- old SSH rules are not revoked automatically.

Verification run by Codex:

- `make help`: passed
- `bash -n` on Loop 1 and Loop 2 shell scripts: passed

AWS-touching Loop 2 commands were verified manually with the `takishiina` test
profile.

Manual test note:

- `make create-key`: passed for `takishiina`
- `make import-key`: passed for `takishiina`; created `takishiina-key` with
  `Owner=takishiina, Name=takishiina-key`
- `make create-security-group`: first attempt failed because the permission set
  allowed tag-scoped `CreateSecurityGroup` for the new security group but did
  not also allow `CreateSecurityGroup` on the target VPC resource. Updated the
  permission-set JSON in `banglab-aws-docs` to add the VPC-side allowance.
- `make create-security-group`: passed after the permission-set update; created
  `takishiina-ssh (sg-0970ff24473e84a81)` with
  `Owner=takishiina, Name=takishiina-ssh`
- `make add-ssh-rule SSH_RULE_NAME=home`: passed; added
  `142.120.164.249/32` with description `takishiina-home`
- final `make ssh-status`: passed; local key, AWS key pair, default VPC,
  security group, owner tags, and SSH inbound rule were all present

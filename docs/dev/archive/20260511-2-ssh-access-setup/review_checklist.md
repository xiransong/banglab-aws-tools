# Loop 2 Review Checklist

## Docs

- [x] `docs/ssh-access-setup.md` explains key pairs and security groups.
- [x] `docs/ssh-access-setup.md` explains owner tags for key pairs and security
      groups.
- [x] `docs/ssh-access-setup.md` matches the updated permission set where key
      pairs and security groups are both owner-tag-scoped.
- [x] `docs/ssh-access-setup.md` explains named SSH rules such as `home` and
      `lab`.
- [x] `docs/dev/loop/api.md` matches the implemented Make targets and scripts.

## Local Checks

- [x] `make help` lists Loop 2 commands.
- [x] shell syntax checks pass.

## Manual AWS Checks

- [x] `make ssh-status`
- [x] `make create-key`
- [x] `make import-key`
- [x] `make import-key` reports `Owner=takishiina` when the key pair already
      exists.
- [x] `make create-security-group`
- [x] `make add-ssh-rule SSH_RULE_NAME=home`
- [x] `make ssh-status` after setup

## Test User

Use:

```text
OWNER=takishiina
AWS_PROFILE=takishiina
KEY_NAME=takishiina-key
SECURITY_GROUP_NAME=takishiina-ssh
AWS account ID=777712053059
```

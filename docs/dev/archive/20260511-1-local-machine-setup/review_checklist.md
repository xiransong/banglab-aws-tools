# Loop 1 Review Checklist

## Docs

- [x] `docs/prerequisites.md` clearly states what users need before using the
      toolbox.
- [x] `docs/local-machine-setup.md` clearly separates user-specific config
      fields from BangLab defaults.
- [x] `docs/local-machine-setup.md` explains the generated AWS SSO profile.
- [x] `docs/dev/loop/api.md` matches the implemented Make targets and scripts.

## Local Commands

- [x] `make help` lists Loop 1 commands.
- [x] `make init-config` creates `config.env` and refuses to overwrite it.
- [x] `make doctor` passes on the development machine.
- [x] `make configure-aws-sso` can generate an AWS config file when
      `AWS_CONFIG_FILE` points to a temporary test path.
- [x] `make aws-login` works for the test user.
- [x] `make aws-whoami` works for the test user after login.

## Test User

Use:

```text
OWNER=takishiina
AWS_PROFILE=takishiina
AWS_ACCOUNT_LABEL=xiransong
AWS_ACCOUNT_ID=777712053059
AWS_SSO_ROLE_NAME=EC2-GPU-Operator
```

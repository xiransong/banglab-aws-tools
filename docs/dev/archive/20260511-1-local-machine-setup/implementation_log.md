# Loop 1 Implementation Log

## 2026-05-11

Implemented the first local machine setup slice.

Added user-facing docs:

- `docs/prerequisites.md`
- `docs/local-machine-setup.md`

Added command/API design:

- `docs/dev/loop/api.md`

Added local config and command interface:

- `.gitignore`
- `config.example.env`
- `Makefile`

Added local setup scripts:

- `scripts/local/init-config.sh`
- `scripts/local/doctor.sh`
- `scripts/local/configure-aws-sso.sh`
- `scripts/local/aws-login.sh`
- `scripts/local/aws-whoami.sh`

Added shared helpers:

- `scripts/lib/config.sh`
- `scripts/lib/log.sh`
- `scripts/lib/checks.sh`

Implementation notes:

- `make doctor` checks only local config and CLI tools.
- `make doctor` does not log in to AWS and does not call AWS STS.
- `make configure-aws-sso` generates the AWS CLI SSO profile from `config.env`.
- `make init-config` and `make doctor` print a safe config summary that
  separates user-specific fields from BangLab defaults.
- `make init-config` prints a highlighted action prompt so users know the
  example values must be replaced before continuing.
- When updating an AWS config file, `configure-aws-sso` creates a timestamped
  backup, removes matching profile/session sections, and appends fresh sections.
- Scripts are invoked through `bash` from the `Makefile`, so executable bits are
  not required for Loop 1.

Verification run:

- `make help`: passed
- `bash -n` on all Loop 1 shell scripts: passed
- `make init-config`: passed and created ignored local `config.env`
- `make init-config` overwrite refusal: passed
- `init-config.sh` with `CONFIG_FILE` pointed at a temporary file: passed
- `make doctor`: passed on the development machine
- `make configure-aws-sso` with `AWS_CONFIG_FILE` pointed at a temporary file:
  passed

Not run yet:

- none

Interactive AWS SSO verification:

- `make configure-aws-sso`: passed with real AWS config
- `make aws-login`: passed for `takishiina`
- `make aws-whoami`: passed for `takishiina`

Observed identity:

```json
{
  "UserId": "AROA3KE2AFNBWPZVNB7UB:takishiina",
  "Account": "777712053059",
  "Arn": "arn:aws:sts::777712053059:assumed-role/AWSReservedSSO_EC2-GPU-Operator_0c66aaf5e2f86c0b/takishiina"
}
```

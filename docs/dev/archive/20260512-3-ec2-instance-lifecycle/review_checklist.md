# Loop 3 Review Checklist

## Docs

- [x] `docs/ec2-instance-lifecycle.md` explains instance recipes.
- [x] `docs/ec2-instance-lifecycle.md` explains launch, status, SSH config,
      stop/start/reboot, and terminate.
- [x] `docs/ec2-instance-lifecycle.md` explains root EBS cost/deletion risks.
- [x] `docs/dev/loop/api.md` matches the implemented Make targets and scripts.

## Local Checks

- [x] `make help` lists Loop 3 commands.
- [x] shell syntax checks pass.
- [x] `git diff --check` passes.
- [x] missing `INSTANCE_NAME` fails before AWS calls.
- [x] recipe command-line override fails before AWS calls.
- [x] missing `CONFIRM_TERMINATE` fails before AWS calls.

## Manual AWS Checks

- [x] `make instances`
- [x] `make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env`
- [x] `make instance-status INSTANCE_NAME=dev`
- [x] `make configure-ssh INSTANCE_NAME=dev`
- [x] `ssh ec2`
- [x] `make stop-instance INSTANCE_NAME=dev`
- [x] `make start-instance INSTANCE_NAME=dev`
- [x] `make configure-ssh INSTANCE_NAME=dev`
- [x] `make reboot-instance INSTANCE_NAME=dev`
- [x] `make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev`
- [x] `make instances` after termination

All Loop 3 commands were manually tested with the `takishiina` profile.

## Test User

Use:

```text
OWNER=takishiina
AWS_PROFILE=takishiina
KEY_NAME=takishiina-key
SECURITY_GROUP_NAME=takishiina-ssh
AWS account ID=777712053059
```

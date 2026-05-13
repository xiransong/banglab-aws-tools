# Loop 4 Review Checklist

## Docs

- [x] `docs/persistent-ebs.md` explains one-time setup and daily workflow.
- [x] `docs/persistent-ebs.md` explains local laptop commands vs
      inside-instance commands.
- [x] `docs/persistent-ebs.md` explains saving and reusing `VOLUME_ID`.
- [x] `docs/persistent-ebs.md` explains `setup-scratch` formatting risk.
- [x] `docs/persistent-ebs.md` explains the root EBS volume ID mistake.
- [x] `docs/dev/loop/api.md` matches implemented Make targets and scripts.

## Local Checks

- [x] `make help` lists Loop 4 commands.
- [x] shell syntax checks pass.
- [x] `git diff --check` passes.
- [x] missing `VOLUME_ID` fails before disk actions in `setup-scratch`.
- [x] missing `VOLUME_ID` fails before disk actions in `mount-scratch`.
- [x] missing `VOLUME_NAME` fails before AWS calls in `create-volume`.
- [x] `VOLUME_SIZE_GB=0` fails before AWS calls in `create-volume`.
- [x] missing `VOLUME_ID` fails before AWS calls in `attach-volume`.

## Manual AWS Checks

- [x] `make volumes`
- [x] `make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500`
- [x] save the printed `VolumeId`
- [x] `make attach-volume VOLUME_ID=vol-... INSTANCE_NAME=dev`

## Manual Inside-Instance Checks

- [x] clone or update `banglab-aws-tools` inside the EC2 instance
- [x] `make setup-scratch VOLUME_ID=vol-... CONFIRM_SETUP_SCRATCH=YES`
- [x] `cd ~/scratch`
- [x] create a small test file under `~/scratch`
- [x] after instance restart/start, run `make mount-scratch VOLUME_ID=vol-...`
- [x] verify the test file still exists

## Test User

Use:

```text
OWNER=takishiina
AWS_PROFILE=takishiina
INSTANCE_NAME=dev
VOLUME_NAME=scratch
AWS account ID=777712053059
```

# Loop 4 Implementation Log

## 2026-05-12

Implemented Persistent EBS Management scripts.

Added Make targets:

- `make volumes`
- `make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500`
- `make attach-volume VOLUME_ID=vol-... INSTANCE_NAME=dev`
- `make setup-scratch VOLUME_ID=vol-... CONFIRM_SETUP_SCRATCH=YES`
- `make mount-scratch VOLUME_ID=vol-...`

Added local laptop EBS scripts:

- `scripts/ebs/volumes.sh`
- `scripts/ebs/create-volume.sh`
- `scripts/ebs/attach-volume.sh`

Added inside-instance scripts:

- `scripts/remote/scratch-common.sh`
- `scripts/remote/setup-scratch.sh`
- `scripts/remote/mount-scratch.sh`

Extended shared helpers:

- `scripts/lib/config.sh`
- `scripts/lib/aws.sh`

Implementation notes:

- `create-volume` creates gp3 volumes in `DEFAULT_AVAILABILITY_ZONE` and waits
  until `available`.
- `create-volume` refuses duplicate `Owner` + `Name` volumes.
- `attach-volume` requires `VOLUME_ID`, verifies `Owner=<OWNER>`, checks AZ
  compatibility, attaches as `/dev/sdf`, and waits until `attached`.
- inside-instance scripts do not call AWS APIs.
- inside-instance scripts resolve the real device through `/dev/disk/by-id`
  using the EBS volume ID without dashes.
- `setup-scratch` refuses to format an existing filesystem and requires
  `CONFIRM_SETUP_SCRATCH=YES`.
- `mount-scratch` refuses to format anything.

Verification run by Codex:

- `make help`: passed
- shell syntax checks for Loop 4 scripts: passed
- `git diff --check`: passed
- local failure path for missing `VOLUME_ID` in `mount-scratch`: passed
- local failure path for missing `VOLUME_ID` in `setup-scratch`: passed
- local failure path for missing `VOLUME_NAME` in `create-volume`: passed
- local failure path for missing `VOLUME_ID` in `attach-volume`: passed
- local failure path for `VOLUME_SIZE_GB=0` in `create-volume`: passed

Not run by Codex:

- AWS-touching Loop 4 commands
- any command that formats or mounts a disk

These should be verified manually with the `takishiina` test profile.

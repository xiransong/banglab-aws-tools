# Loop 3 Implementation Log

## 2026-05-12

Implemented EC2 instance lifecycle scripts for owner-tagged instances.

Added Make targets:

- `make instances`
- `make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env`
- `make instance-status INSTANCE_NAME=dev`
- `make configure-ssh INSTANCE_NAME=dev`
- `make stop-instance INSTANCE_NAME=dev`
- `make start-instance INSTANCE_NAME=dev`
- `make reboot-instance INSTANCE_NAME=dev`
- `make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev`

Added EC2 scripts:

- `scripts/ec2/instances.sh`
- `scripts/ec2/launch-instance.sh`
- `scripts/ec2/instance-status.sh`
- `scripts/ec2/configure-ssh.sh`
- `scripts/ec2/stop-instance.sh`
- `scripts/ec2/start-instance.sh`
- `scripts/ec2/reboot-instance.sh`
- `scripts/ec2/terminate-instance.sh`

Extended shared helpers:

- `scripts/lib/config.sh`
- `scripts/lib/aws.sh`

Implementation notes:

- `launch-instance` reads launch settings strictly from `INSTANCE_CONFIG`.
- `launch-instance` tags both the EC2 instance and root EBS volume with
  `Owner` and `Name`.
- `launch-instance` waits until the instance reaches `running`.
- `instances` lists all owner-tagged instances returned by AWS, including
  recently terminated records.
- `instances` uses per-instance blocks instead of a wide table so the output is
  readable in narrow terminals.
- single-instance lifecycle commands ignore terminated instances.
- `configure-ssh` writes a managed block in `~/.ssh/config`.
- `configure-ssh` refuses to create a duplicate host alias if the alias already
  exists outside a `banglab-aws-tools` managed block.
- `terminate-instance` requires `CONFIRM_TERMINATE` to match `INSTANCE_NAME`.

Verification run by Codex:

- `make help`: passed
- `bash -n` on Loop 3 shell scripts: passed
- `git diff --check`: passed
- local failure path for missing `INSTANCE_NAME`: passed
- local failure path for recipe command-line override: passed
- local failure path for missing `CONFIRM_TERMINATE`: passed

Not run by Codex:

- AWS-touching Loop 3 commands
- any command that launches, starts, stops, reboots, or terminates an instance

These should be verified manually with the `takishiina` test profile.

Manual test note:

- `make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env`
  initially failed because `ec2:RunInstances` was denied on
  `key-pair/takishiina-key`.
- Smoking gun: the permission set allowed `RunInstances` with an
  `aws:RequestTag/Owner` condition on `Resource="*"`. `RunInstances` is
  authorized against launch dependency resources such as key pairs and security
  groups, where request tags do not apply.
- Updated `banglab-aws-docs/policy/EC2-GPU-Operator.json` to split
  `RunInstances` permissions into created resources, owned launch dependencies,
  and untagged launch dependencies.

Successful manual test:

- `make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env`
  launched `i-0a2d33a07be6c6cf0`.
- the launch waited through `pending` and reached `running`.
- public IP was `44.202.207.72`.
- `make configure-ssh INSTANCE_NAME=dev` first correctly refused to overwrite
  an unmanaged existing `Host ec2`.
- after the old host entry was removed, `make configure-ssh INSTANCE_NAME=dev`
  updated `~/.ssh/config`.
- `ssh ec2` connected successfully to Ubuntu 22.04.5 LTS.
- `make instances` showed the running `dev` instance.
- `make instances` output was changed from a wide table to compact
  per-instance blocks for narrow terminals.
- `ssh ec2` can briefly fail with `Connection refused` after EC2 reports
  `running`; launch/configure-ssh output now tells users to wait 30-60 seconds
  and retry.
- `make stop-instance INSTANCE_NAME=dev` was manually tested and successfully
  requested stop for `i-08eabdbffb6c6cf7a`.
- `make start-instance INSTANCE_NAME=dev` exposed an AWS timing issue: after
  `StartInstances` is accepted, `DescribeInstances` may briefly still report
  `stopped`. The wait loop now tolerates that state instead of failing.
- `make configure-ssh` was adding an extra blank line before its managed block
  on repeated runs. The rewrite now trims trailing blank lines before appending
  the managed block.
- All Loop 3 commands were manually tested with the `takishiina` profile before
  closing the loop.

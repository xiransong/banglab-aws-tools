# Loop 3 API: EC2 Instance Lifecycle

This document defines the command interface for Loop 3 before implementation.

## User Commands

All user-facing commands are Make targets run from the repo root.

```bash
make instances
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make instance-status INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev SSH_HOST=dev
make stop-instance INSTANCE_NAME=dev
make start-instance INSTANCE_NAME=dev
make reboot-instance INSTANCE_NAME=dev
make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
```

## Instance Recipes

Committed recipes:

```text
instances/m7i-flex-xlarge.env
instances/g4dn-xlarge.env
```

Required recipe variables:

```text
AMI_ID
INSTANCE_TYPE
ROOT_VOLUME_SIZE_GB
```

Launch settings come only from `INSTANCE_CONFIG`. Loop 3 does not support
command-line overrides for `AMI_ID`, `INSTANCE_TYPE`, or
`ROOT_VOLUME_SIZE_GB`.

## Shared Inputs

All commands load `config.env`.

Relevant values:

```text
OWNER
AWS_PROFILE
AWS_REGION
DEFAULT_AVAILABILITY_ZONE
SSH_KEY_PATH
KEY_NAME
SECURITY_GROUP_NAME
```

## `make instances`

Purpose: list owned EC2 instances.

Inputs:

- `config.env`
- AWS CLI profile from Loop 1

Expected behavior:

- lists instances with `Owner=${OWNER}`
- includes running, pending, stopping, stopped, and recently terminated
  instances
- prints readable per-instance blocks with:
  - `name`
  - `id`
  - `state`
  - `type`
  - `public_ip`
  - `private_ip`
  - `launch_time`
- does not create, modify, or delete resources

Planned AWS command shape:

```bash
aws ec2 describe-instances \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --filters "Name=tag:Owner,Values=${OWNER}"
```

## `make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=...`

Purpose: launch one owner-tagged EC2 instance.

Required inputs:

- `INSTANCE_NAME`
- `INSTANCE_CONFIG`
- recipe variables:
  - `AMI_ID`
  - `INSTANCE_TYPE`
  - `ROOT_VOLUME_SIZE_GB`

Expected behavior:

- validates `INSTANCE_NAME`
- loads and validates `INSTANCE_CONFIG`
- rejects missing command-line inputs
- rejects command-line overrides for recipe variables
- resolves the default VPC
- resolves a subnet in `DEFAULT_AVAILABILITY_ZONE`
- verifies `KEY_NAME` exists and has `Owner=${OWNER}`
- verifies `SECURITY_GROUP_NAME` exists and has `Owner=${OWNER}`
- launches exactly one instance
- applies instance tags:
  - `Owner=${OWNER}`
  - `Name=${INSTANCE_NAME}`
- sets root EBS size to `ROOT_VOLUME_SIZE_GB`
- waits until the instance reaches `running`
- prints instance ID, public IP, and next commands
- reminds the user that SSH may take another 30-60 seconds after EC2 reports
  `running`

Planned AWS command shape:

```bash
aws ec2 run-instances \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --image-id "${AMI_ID}" \
  --instance-type "${INSTANCE_TYPE}" \
  --key-name "${KEY_NAME}" \
  --security-group-ids "${SECURITY_GROUP_ID}" \
  --subnet-id "${SUBNET_ID}" \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${ROOT_VOLUME_SIZE_GB},\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${INSTANCE_NAME}}]" \
  --count 1
```

After launch:

```bash
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"
```

## `make instance-status INSTANCE_NAME=dev`

Purpose: show detailed status for one named owned instance.

Required inputs:

- `INSTANCE_NAME`

Expected behavior:

- resolves one non-terminated instance with:
  - `Owner=${OWNER}`
  - `Name=${INSTANCE_NAME}`
- fails clearly if no non-terminated instance matches
- fails clearly if multiple non-terminated instances match
- prints details including:
  - instance ID
  - state
  - instance type
  - AMI ID
  - public IP
  - private IP
  - launch time
  - availability zone
  - key name
  - security group IDs/names
  - root device name

## `make configure-ssh INSTANCE_NAME=dev [SSH_HOST=ec2]`

Purpose: update `~/.ssh/config` for terminal SSH and VS Code Remote SSH.

Required inputs:

- `INSTANCE_NAME`

Optional inputs:

- `SSH_HOST`, default `ec2`

Expected behavior:

- resolves one non-terminated instance with:
  - `Owner=${OWNER}`
  - `Name=${INSTANCE_NAME}`
- requires the instance state to be `running`
- requires a public IP
- updates `~/.ssh/config`
- writes or replaces a managed block for `SSH_HOST`
- refuses to create a duplicate if `SSH_HOST` already exists outside a
  `banglab-aws-tools` managed block
- uses:
  - `Host ${SSH_HOST}`
  - `HostName ${PUBLIC_IP}`
  - `User ubuntu`
  - `IdentityFile ${SSH_KEY_PATH}`
  - `IdentitiesOnly yes`
- prints the next command:

```bash
ssh "${SSH_HOST}"
```

Managed block shape:

```sshconfig
# banglab-aws-tools begin ec2
Host ec2
  HostName 44.214.107.98
  User ubuntu
  IdentityFile /Users/songxiran/.ssh/takishiina
  IdentitiesOnly yes
# banglab-aws-tools end ec2
```

## `make stop-instance INSTANCE_NAME=dev`

Purpose: stop one named owned instance.

Required inputs:

- `INSTANCE_NAME`

Expected behavior:

- resolves one non-terminated instance with `Owner=${OWNER}` and
  `Name=${INSTANCE_NAME}`
- calls `ec2:StopInstances`
- prints a reminder that root EBS may still cost money

## `make start-instance INSTANCE_NAME=dev`

Purpose: start one named owned instance.

Required inputs:

- `INSTANCE_NAME`

Expected behavior:

- resolves one non-terminated instance with `Owner=${OWNER}` and
  `Name=${INSTANCE_NAME}`
- calls `ec2:StartInstances`
- waits until the instance reaches `running`
- prints a reminder to rerun `make configure-ssh`
- tolerates the brief period where AWS may still report `stopped` immediately
  after accepting a start request

## `make reboot-instance INSTANCE_NAME=dev`

Purpose: reboot one named owned instance.

Required inputs:

- `INSTANCE_NAME`

Expected behavior:

- resolves one non-terminated instance with `Owner=${OWNER}` and
  `Name=${INSTANCE_NAME}`
- requires the instance state to be `running`
- calls `ec2:RebootInstances`

## `make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev`

Purpose: terminate one named owned instance.

Required inputs:

- `INSTANCE_NAME`
- `CONFIRM_TERMINATE`

Expected behavior:

- requires `CONFIRM_TERMINATE` to exactly match `INSTANCE_NAME`
- resolves one non-terminated instance with `Owner=${OWNER}` and
  `Name=${INSTANCE_NAME}`
- calls `ec2:TerminateInstances`
- prints a warning that the instance and usually its root EBS volume are deleted

## Instance Resolution

Most single-instance commands resolve by:

```text
tag:Owner=<OWNER>
tag:Name=<INSTANCE_NAME>
instance-state-name=pending,running,stopping,stopped
```

Terminated instances are shown by `make instances` but ignored for
single-instance lifecycle commands.

If zero instances match, the command should fail clearly.

If multiple instances match, the command should fail clearly and ask the user to
choose a unique `INSTANCE_NAME` or terminate duplicates.

## Script Mapping

```text
make instances          -> scripts/ec2/instances.sh
make launch-instance    -> scripts/ec2/launch-instance.sh
make instance-status    -> scripts/ec2/instance-status.sh
make configure-ssh      -> scripts/ec2/configure-ssh.sh
make stop-instance      -> scripts/ec2/stop-instance.sh
make start-instance     -> scripts/ec2/start-instance.sh
make reboot-instance    -> scripts/ec2/reboot-instance.sh
make terminate-instance -> scripts/ec2/terminate-instance.sh
```

Shared helpers:

```text
scripts/lib/aws.sh
scripts/lib/config.sh
scripts/lib/log.sh
scripts/lib/checks.sh
```

## Policy Note

The current `EC2-GPU-Operator` permission set requires `Owner=${OWNER}` when
launching instances and limits lifecycle actions to instances with the matching
`Owner` resource tag.

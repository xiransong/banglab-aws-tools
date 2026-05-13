# Loop 4 API: Persistent EBS Management

This document defines the command interface for Loop 4 before implementation.

## User Commands

Local laptop commands:

```bash
make volumes
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
```

Inside-instance commands:

```bash
make setup-scratch VOLUME_ID=vol-0123456789abcdef0 CONFIRM_SETUP_SCRATCH=YES
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

## Shared Local AWS Inputs

Local laptop commands load `config.env`.

Relevant values:

```text
OWNER
AWS_PROFILE
AWS_REGION
DEFAULT_AVAILABILITY_ZONE
```

## `make volumes`

Purpose: list owned persistent EBS volumes.

Inputs:

- `config.env`
- AWS CLI profile from Loop 1

Expected behavior:

- lists EBS volumes with `Owner=${OWNER}`
- helps users retrieve the `VolumeId` needed for daily attach/mount workflows
- prints compact per-volume blocks with:
  - `name`
  - `id`
  - `state`
  - `size_gb`
  - `type`
  - `availability_zone`
  - `attached_instance`
  - `device`
- does not create, modify, or delete resources

Planned AWS command shape:

```bash
aws ec2 describe-volumes \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --filters "Name=tag:Owner,Values=${OWNER}"
```

## `make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500`

Purpose: create one owner-tagged gp3 persistent EBS volume.

Required inputs:

- `VOLUME_NAME`
- `VOLUME_SIZE_GB`

Expected behavior:

- validates `VOLUME_NAME`
- validates `VOLUME_SIZE_GB`
- refuses to create a duplicate non-deleted volume with:
  - `Owner=${OWNER}`
  - `Name=${VOLUME_NAME}`
- creates a `gp3` volume in `DEFAULT_AVAILABILITY_ZONE`
- applies tags:
  - `Owner=${OWNER}`
  - `Name=${VOLUME_NAME}`
- waits until the volume reaches `available`
- prints the new `VolumeId` prominently
- tells the user to save the `VolumeId`

Planned AWS command shape:

```bash
aws ec2 create-volume \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --availability-zone "${DEFAULT_AVAILABILITY_ZONE}" \
  --size "${VOLUME_SIZE_GB}" \
  --volume-type gp3 \
  --tag-specifications "ResourceType=volume,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${VOLUME_NAME}}]"
```

After creation:

```bash
aws ec2 wait volume-available --volume-ids "${VOLUME_ID}"
```

## `make attach-volume VOLUME_ID=... INSTANCE_NAME=dev`

Purpose: attach one owned EBS volume to one owned running EC2 instance.

Required inputs:

- `VOLUME_ID`
- `INSTANCE_NAME`

Expected behavior:

- validates `VOLUME_ID`
- validates `INSTANCE_NAME`
- resolves the volume by `VOLUME_ID`
- verifies the volume has `Owner=${OWNER}`
- resolves one active instance with:
  - `Owner=${OWNER}`
  - `Name=${INSTANCE_NAME}`
- requires the instance state to be `running`
- requires the volume state to be `available`
- requires the volume and instance to be in the same availability zone
- attaches the volume as `/dev/sdf`
- waits until the attachment state is `attached`
- prints next commands for SSH and inside-instance setup/mount

Planned AWS command shape:

```bash
aws ec2 attach-volume \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --volume-id "${VOLUME_ID}" \
  --instance-id "${INSTANCE_ID}" \
  --device /dev/sdf
```

## Inside-Instance Inputs

Inside-instance commands do not use AWS APIs.

Required input:

```text
VOLUME_ID
```

Shared local values:

```text
SCRATCH_MOUNT=${HOME}/scratch
FS_TYPE=ext4
```

Device resolution:

```text
VOLUME_ID_NODASH=${VOLUME_ID//-/}
/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${VOLUME_ID_NODASH}
```

If multiple matching by-id links exist, prefer the unsuffixed link. If only
suffixed links exist, use the first one.

## `make setup-scratch VOLUME_ID=...`

Purpose: one-time setup for a newly attached blank persistent EBS volume.

Expected behavior:

- validates `VOLUME_ID`
- resolves the Linux block device from `VOLUME_ID`
- refuses if no device is found
- refuses if the resolved disk has partitions or mounted children, which helps
  catch accidentally passing the root EBS volume ID
- refuses if the device already has a filesystem
- prints a dry-run summary:
  - volume ID
  - by-id link
  - real block device
  - filesystem state
  - mount point
  - planned actions
- requires `CONFIRM_SETUP_SCRATCH=YES`
- creates an `ext4` filesystem
- creates `~/scratch`
- mounts the filesystem at `~/scratch`
- writes a UUID-based `/etc/fstab` entry with `nofail`
- changes ownership of `~/scratch` to the current user
- creates standard directories under `~/scratch`

Standard directories:

```text
repos
data
outputs
transfer
```

This command may use `sudo`.

## `make mount-scratch VOLUME_ID=...`

Purpose: daily mount for an already initialized persistent EBS volume.

Expected behavior:

- validates `VOLUME_ID`
- resolves the Linux block device from `VOLUME_ID`
- refuses if no device is found
- refuses with a root-volume hint if the whole disk has no filesystem but has
  partitions or mounted children
- refuses if the device has no filesystem
- creates `~/scratch`
- mounts the filesystem at `~/scratch`
- ensures a UUID-based `/etc/fstab` entry exists
- changes ownership of `~/scratch` to the current user
- does not format anything
- prints `cd ~/scratch`

This command may use `sudo`.

## Script Mapping

```text
make volumes        -> scripts/ebs/volumes.sh
make create-volume  -> scripts/ebs/create-volume.sh
make attach-volume  -> scripts/ebs/attach-volume.sh
make setup-scratch  -> scripts/remote/setup-scratch.sh
make mount-scratch  -> scripts/remote/mount-scratch.sh
```

Shared helpers:

```text
scripts/lib/aws.sh
scripts/lib/config.sh
scripts/lib/log.sh
```

## Policy Note

The current `EC2-GPU-Operator` permission set already includes volume creation
and volume management permissions scoped by `Owner` tag. `AttachVolume` should
be manually tested because AWS authorizes attach against both the volume and the
instance.

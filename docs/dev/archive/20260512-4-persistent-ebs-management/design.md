# Loop 4 Design: Persistent EBS Management

Started: 2026-05-12

## Goal

Design the persistent EBS workflow for `banglab-aws-tools`.

This loop should let a lab member:

- list their owned EBS volumes
- create one persistent owner-tagged EBS volume
- attach that volume to an owned EC2 instance using the volume ID
- initialize the attached volume once from inside the EC2 instance
- mount the initialized volume at `~/scratch` for daily work

This loop intentionally does not include detach or delete commands.

## Workflow Shape

Persistent EBS has two phases:

```text
one-time setup
daily attach/mount workflow
```

One-time setup:

```bash
# local laptop
make volumes
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev
ssh ec2

# inside EC2 instance
git clone <banglab-aws-tools-url>
cd banglab-aws-tools
make setup-scratch VOLUME_ID=vol-0123456789abcdef0 CONFIRM_SETUP_SCRATCH=YES
```

Daily workflow:

```bash
# local laptop
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev
ssh ec2

# inside EC2 instance
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
cd ~/scratch
```

## Prerequisites

The local laptop should have completed:

```bash
make doctor
make aws-login
make aws-whoami
make create-key
make import-key
make create-security-group
make add-ssh-rule SSH_RULE_NAME=home
```

The user should also have an owned instance from Loop 3:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make configure-ssh INSTANCE_NAME=dev
```

The inside-instance commands assume:

- the user can SSH into the instance
- this repo is cloned on the instance
- the persistent EBS volume is attached to the instance
- the user knows the persistent EBS volume ID
- the intended mount point is `~/scratch`

Test user:

```text
Name: Taki Shiina
Username / Owner: takishiina
Permission set: EC2-GPU-Operator
AWS account: xiransong
AWS account ID: 777712053059
```

## Scope

In scope:

- list owned EBS volumes
- create one gp3 EBS volume with owner tags
- attach one owned volume to one owned instance
- detect the attached EBS device from inside an instance
- one-time filesystem creation for a blank persistent EBS volume
- mount the volume at `~/scratch`
- add a stable mount entry so `mount-scratch` can be used after reboot/start

Out of scope:

- detaching volumes
- deleting volumes
- snapshots
- resizing volumes or filesystems
- multiple persistent volumes per user
- cross-AZ migration
- restoring from backups
- encryption customization
- non-`~/scratch` mount points

## Policy Constraints

The `EC2-GPU-Operator` permission set currently allows:

- `ec2:CreateVolume` only when the request includes the user's own `Owner` tag
- `ec2:CreateTags` during volume creation with `Owner` and `Name`
- volume management actions only for volumes with the user's own `Owner` tag
- `ec2:AttachVolume` and `ec2:DetachVolume` with an owner-tag condition
- EC2 describe actions

Attach is likely the action to test carefully. AWS authorizes `AttachVolume`
against both the volume and the instance. The policy may need to ensure both
resources are owner-tagged, similar to the split `RunInstances` policy shape
from Loop 3.

## Naming And Ownership

Users should provide a `VOLUME_NAME` such as:

```text
scratch
```

The toolbox should tag the EBS volume:

```text
Owner=<OWNER>
Name=<VOLUME_NAME>
```

The toolbox should resolve volumes by both tags:

```text
tag:Owner=<OWNER>
tag:Name=<VOLUME_NAME>
```

If multiple non-deleted volumes match the same `VOLUME_NAME`, commands should
fail clearly and ask the user to resolve the duplicate.

The persistent volume ID should be treated as the source of truth after volume
creation:

```text
vol-0123456789abcdef0
```

The user should save this ID. It is required for `attach-volume`,
`setup-scratch`, and `mount-scratch`.

## Local Laptop Commands

These commands call AWS APIs and should run from the user's local laptop:

```bash
make volumes
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
```

### `make volumes`

List owned EBS volumes.
Users can use this command to retrieve the `VolumeId` needed for daily
attach/mount workflows.

Output should use compact per-volume blocks, similar to `make instances`:

```text
volume 1:
  name: scratch
  id: vol-...
  state: available
  size_gb: 500
  type: gp3
  availability_zone: us-east-1a
  attached_instance: -
  device: -
```

### `make create-volume`

Create an owner-tagged gp3 EBS volume.

Required inputs:

```text
VOLUME_NAME
VOLUME_SIZE_GB
```

Defaults and derived values:

```text
VOLUME_TYPE=gp3
AVAILABILITY_ZONE=DEFAULT_AVAILABILITY_ZONE
Owner=<OWNER>
Name=<VOLUME_NAME>
```

The command should refuse to create a second non-deleted volume with the same
`Owner` and `Name`.

The command should print the new `VolumeId` prominently and tell the user to
save it.

### `make attach-volume`

Attach an owned volume to an owned instance.

Required inputs:

```text
VOLUME_ID
INSTANCE_NAME
```

Expected behavior:

- resolve exactly one owned volume by `VOLUME_ID`
- verify the volume has `Owner=<OWNER>`
- resolve exactly one owned active instance by `INSTANCE_NAME`
- require the instance to be `running`
- require the volume to be `available`
- require the volume and instance to be in the same availability zone
- attach the volume using a predictable device name
- print the next command: `ssh ec2`, then `make setup-scratch` or
  `make mount-scratch` inside the instance

Planned device name:

```text
/dev/sdf
```

On Nitro-based instances, Linux will usually expose this as an NVMe device such
as `/dev/nvme1n1`. Inside-instance commands should detect the real device by
checking block devices.

## Inside-Instance Commands

These commands should run inside the EC2 instance over SSH:

```bash
make setup-scratch VOLUME_ID=vol-0123456789abcdef0 CONFIRM_SETUP_SCRATCH=YES
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

They should not call AWS APIs. They should inspect local block devices.

Inside-instance scripts should resolve the real Linux device from the EBS volume
ID by looking under `/dev/disk/by-id`:

```text
/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<volume-id-without-dashes>
```

This mirrors the proven pattern from the older `MyAWS` workflow and avoids
guessing among `/dev/nvme*` devices.

### `make setup-scratch`

One-time setup for a newly attached blank persistent EBS volume.

Expected behavior:

- require `VOLUME_ID`
- resolve exactly one block device from `VOLUME_ID`
- refuse if no matching device is found
- refuse if the candidate already has a filesystem
- show a dry-run summary and require `CONFIRM_SETUP_SCRATCH=YES` before
  formatting
- create an `ext4` filesystem
- create `~/scratch`
- mount the filesystem at `~/scratch`
- add an `/etc/fstab` entry using the filesystem UUID
- make the mounted directory owned by the current user

This command may need `sudo` for filesystem, mount, and fstab operations.

Safety principle:

```text
format only when the target disk is clearly blank
```

### `make mount-scratch`

Daily mount command for an already initialized persistent EBS volume.

Expected behavior:

- require `VOLUME_ID`
- resolve exactly one block device from `VOLUME_ID`
- create `~/scratch` if missing
- mount the volume using the existing `/etc/fstab` entry or filesystem UUID
- refuse to format anything
- be safe to run after each login/start
- print `cd ~/scratch` as the next command

## Mount Point

The persistent EBS volume should mount at:

```text
~/scratch
```

Do not mount persistent EBS directly at `~/`.

## User-Facing Docs To Design

This loop should draft and later promote:

```text
docs/persistent-ebs.md
```

The doc should cover:

- why persistent EBS exists separately from the EC2 root volume
- one-time setup workflow
- daily attach/mount workflow
- local laptop commands vs inside-instance commands
- why users should save and reuse the EBS volume ID
- why the mount point is `~/scratch`
- what `setup-scratch` does and why it is conservative
- what `mount-scratch` does and why it is safe for daily use
- warnings that EBS volumes continue to cost money when the instance is stopped
  or terminated
- that detach/delete/snapshot/resize are out of scope for this loop

## Planned Repo Structure For This Loop

```text
banglab-aws-tools/
├── docs/
│   └── persistent-ebs.md
└── scripts/
    ├── ebs/
    │   ├── volumes.sh
    │   ├── create-volume.sh
    │   └── attach-volume.sh
    └── remote/
        ├── setup-scratch.sh
        └── mount-scratch.sh
```

Shared AWS helpers in `scripts/lib/aws.sh` should be extended for local laptop
EBS commands. Inside-instance scripts should avoid sourcing AWS helpers unless
they truly need AWS APIs.

## Proposed Make Targets

```bash
make volumes
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
make setup-scratch VOLUME_ID=vol-0123456789abcdef0 CONFIRM_SETUP_SCRATCH=YES
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

Target behavior:

- `make volumes`: list owned EBS volumes
- `make create-volume`: create one owner-tagged gp3 persistent EBS volume
- `make attach-volume`: attach one owned volume ID to one owned running instance
- `make setup-scratch`: one-time inside-instance format and mount at
  `~/scratch`
- `make mount-scratch`: daily inside-instance mount at `~/scratch`

## Open Questions

Resolved:

1. `create-volume` should wait until the volume reaches `available`.
2. `attach-volume` should wait until the attachment state reaches `attached`.
3. `attach-volume` should use `/dev/sdf` in Loop 4. Do not make the device name
   configurable yet.
4. `setup-scratch` should add an `/etc/fstab` entry automatically, using the
   filesystem UUID and `nofail`.
5. `setup-scratch` and `mount-scratch` should require `VOLUME_ID`; no
   interactive prompt in Loop 4.

## Done Criteria

This loop is done when:

- `docs/persistent-ebs.md` is drafted and reviewed
- command/API shape is documented
- Make targets are implemented
- local laptop EBS scripts are implemented
- inside-instance scratch scripts are implemented
- commands work with the Taki test profile
- `status_and_plan.md` is updated
- loop docs are archived according to `docs/dev/README.md`

## Loop Todo

1. Draft design doc: done
   - `docs/dev/loop/design.md`

2. Resolve open questions: done

3. Draft user-facing docs: done
   - `docs/persistent-ebs.md`

4. Draft command/API docs: done
   - `docs/dev/loop/api.md`

5. Add Make targets: done
   - `volumes`
   - `create-volume`
   - `attach-volume`
   - `setup-scratch`
   - `mount-scratch`

6. Implement local laptop EBS scripts: done

7. Implement inside-instance scratch scripts: done

8. Verify with test user assumptions

9. Close and archive Loop 4

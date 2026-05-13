# Persistent EBS

This page covers the persistent EBS workflow for research storage.

EC2 instances are disposable. The persistent EBS volume is where long-lived
work should live.

The persistent EBS volume should be mounted at:

```text
~/scratch
```

Do not mount persistent EBS directly at `~/`.

This workflow does not include detach, delete, snapshot, or resize commands.

## Two Phases

Persistent EBS has two phases:

```text
one-time setup
daily attach/mount workflow
```

One-time setup creates and initializes the persistent volume.

Daily workflow reuses the same volume with a new or existing EC2 instance.

## Local Commands And Instance Commands

Some commands run on your local laptop because they call AWS:

```bash
make volumes
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
```

Some commands run inside the EC2 instance because they touch Linux disks:

```bash
make setup-scratch VOLUME_ID=vol-0123456789abcdef0 CONFIRM_SETUP_SCRATCH=YES
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

The inside-instance commands may ask for `sudo`.

## Step 1: List Volumes

Run from your local laptop:

```bash
make volumes
```

This lists your owned EBS volumes.
Use this command whenever you need to retrieve the `VolumeId` for your daily
workflow.

Expected format:

```text
volume 1:
  name: scratch
  id: vol-0123456789abcdef0
  state: available
  size_gb: 500
  type: gp3
  availability_zone: us-east-1a
  attached_instance: -
  device: -
```

## AWS Console: Review Volumes

The CLI is the primary workflow for creating and attaching volumes. The AWS
Console is useful for checking EBS state visually.

Open the AWS Console through the AWS Access Portal, select the BangLab account
and `EC2-GPU-Operator` permission set, then set the region to:

```text
us-east-1
```

Go to **EC2 -> Volumes**. Use the `Owner` and `Name` tags to identify your
resources:

```text
Owner=<username>
Name=<volume name>
```

For each volume, review:

- volume ID
- state
- size
- availability zone
- attached instance
- device name

Root volumes belong to EC2 instances and are usually not the persistent scratch
volume you want for daily work. Persistent scratch volumes are the volumes you
created with `make create-volume`; use `make volumes` to retrieve their
`VolumeId`.

## Step 2: Create A Persistent Volume

Run from your local laptop:

```bash
make create-volume VOLUME_NAME=scratch VOLUME_SIZE_GB=500
```

The toolbox creates a `gp3` EBS volume in the default availability zone:

```text
DEFAULT_AVAILABILITY_ZONE=us-east-1a
```

The volume is tagged with:

```text
Owner=<OWNER>
Name=<VOLUME_NAME>
```

The command waits until the volume reaches `available`.

Save the printed `VolumeId`. You will need it for attach, setup, and mount:

```text
vol-0123456789abcdef0
```

If you forget it later, run:

```bash
make volumes
```

## Step 3: Attach The Volume

Launch or start an EC2 instance first:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make configure-ssh INSTANCE_NAME=dev
```

Attach the volume from your local laptop:

```bash
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
```

The command checks that:

- the volume belongs to you
- the instance belongs to you
- the instance is running
- the volume is available
- the volume and instance are in the same availability zone

It attaches the volume as:

```text
/dev/sdf
```

On the EC2 instance, this usually appears as an NVMe device such as:

```text
/dev/nvme1n1
```

The inside-instance commands use `VOLUME_ID` to find the real device.

## Step 4: One-Time Scratch Setup

SSH into the instance:

```bash
ssh ec2
```

Clone this repo on the instance if needed, then run:

```bash
cd banglab-aws-tools
make setup-scratch VOLUME_ID=vol-0123456789abcdef0 CONFIRM_SETUP_SCRATCH=YES
```

This command is for a new blank persistent EBS volume.

It should:

- find the attached device from `VOLUME_ID`
- refuse to continue if the volume already has a filesystem
- show a dry-run summary
- require `CONFIRM_SETUP_SCRATCH=YES`
- create an `ext4` filesystem
- mount it at `~/scratch`
- add a UUID-based `/etc/fstab` entry with `nofail`
- make `~/scratch` owned by the current user

Run this once per persistent EBS volume.

## Step 5: Daily Mount

For daily work, after the volume is attached and you SSH into the instance:

```bash
git clone https://github.com/xiransong/banglab-aws-tools.git
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
cd ~/scratch
```

`mount-scratch` should not format anything. It mounts an already initialized
volume at `~/scratch`.

If you accidentally pass the root EBS volume ID, `mount-scratch` should refuse
with an error saying that the device has partitions or mounted children. Go back
to your local laptop and run `make volumes`; choose the persistent scratch
volume ID, not the root volume attached to the EC2 instance.

## Daily Workflow

From your local laptop:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev
ssh ec2
```

Inside the EC2 instance:

```bash
git clone https://github.com/xiransong/banglab-aws-tools.git
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
cd ~/scratch
```

## Cost Reminder

Persistent EBS volumes continue to cost money when:

- the instance is stopped
- the instance is terminated
- the volume is not attached to any instance

This is intentional: the volume persists so your data persists.

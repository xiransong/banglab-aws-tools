# EC2 Instance Lifecycle

This page covers the basic EC2 instance workflow:

```text
list -> launch -> configure SSH -> use -> stop/start/reboot -> terminate
```

This workflow manages EC2 instances and their root EBS volumes. It does not
create or manage separate persistent research EBS volumes.

Before starting, complete:

```bash
make doctor
make aws-login
make aws-whoami
make create-key
make import-key
make create-security-group
make add-ssh-rule SSH_RULE_NAME=home
```

## Instance Recipes

Launching an instance requires an instance recipe file.

The recipe controls:

```text
AMI_ID
INSTANCE_TYPE
ROOT_VOLUME_SIZE_GB
```

The toolbox includes two starter recipes:

```text
instances/m7i-flex-xlarge.env
instances/g4dn-xlarge.env
```

Use the CPU recipe for light development:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
```

Use the GPU recipe when you need a GPU:

```bash
make launch-instance INSTANCE_NAME=gpu INSTANCE_CONFIG=instances/g4dn-xlarge.env
```

The default AMI in both recipes is:

```text
Deep Learning Base AMI with Single CUDA (Ubuntu 22.04) 20260130
AMI ID: ami-0252d9c82e6b8fa85
```

This AMI is for x86_64 instances. Do not use it with ARM/Graviton instance
types.

The default root EBS size is `200` GB. This root volume holds the OS, package
environments, Docker cache, cloned repos, and temporary working files. Stopped
instances may still have root EBS storage costs.

## Step 1: List Instances

Run:

```bash
make instances
```

This lists your owned instances, including running, stopped, and recently
terminated instances.

Expected format:

```text
instance 1:
  name: dev
  id: i-0a2d33a07be6c6cf0
  state: running
  type: m7i-flex.xlarge
  public_ip: 44.202.207.72
  private_ip: 172.31.12.155
  launch_time: 2026-05-12T19:44:55+00:00
```

Terminated instance records disappear from AWS after some time.

## Step 2: Launch An Instance

Launch requires an instance name and a recipe file:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
```

The toolbox launches the instance with:

```text
Owner=<OWNER>
Name=<INSTANCE_NAME>
```

It also reuses the key pair and security group from SSH Access Setup:

```text
key pair: <OWNER>-key
security group: <OWNER>-ssh
```

The command waits until the instance reaches `running`, then prints the public
IP and next commands.

After EC2 reports `running`, Ubuntu may still need a short time to finish
booting SSH. If `ssh ec2` says `Connection refused`, wait 30-60 seconds and try
again.

## Step 3: Check One Instance

Run:

```bash
make instance-status INSTANCE_NAME=dev
```

This shows detailed status for the named instance.

## Step 4: Configure SSH

After the instance is running, update your local SSH config:

```bash
make configure-ssh INSTANCE_NAME=dev
```

By default, this creates or updates the `ec2` SSH host alias:

```sshconfig
# banglab-aws-tools begin ec2
Host ec2
  HostName 44.214.107.98
  User ubuntu
  IdentityFile /Users/songxiran/.ssh/takishiina
  IdentitiesOnly yes
# banglab-aws-tools end ec2
```

Then connect with normal SSH:

```bash
ssh ec2
```

You can also use `ec2` from VS Code Remote SSH.

If SSH says `Connection refused`, the instance is usually still finishing its
boot process. Wait 30-60 seconds and retry.

If `~/.ssh/config` already has a hand-written `Host ec2` entry, the command
will ask you to remove that old entry or choose a different `SSH_HOST`. This
avoids duplicate SSH aliases.

To choose a different alias:

```bash
make configure-ssh INSTANCE_NAME=dev SSH_HOST=dev
ssh dev
```

If you stop and later start an instance, its public IP may change. Rerun
`make configure-ssh` after the instance is running again.

## Step 5: Stop, Start, Or Reboot

Stop an instance:

```bash
make stop-instance INSTANCE_NAME=dev
```

Start it again:

```bash
make start-instance INSTANCE_NAME=dev
```

Reboot it:

```bash
make reboot-instance INSTANCE_NAME=dev
```

Stopping pauses compute charges, but root EBS storage may still cost money.
After starting a stopped instance, rerun `make configure-ssh` because the public
IP may have changed. AWS may briefly keep reporting the instance as `stopped`
right after a start request; the toolbox waits through that transition.

## Step 6: Terminate

Terminate only when you are done with the instance:

```bash
make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
```

The confirmation value must exactly match `INSTANCE_NAME`.

Termination deletes the EC2 instance and usually deletes its root EBS volume.
Do not terminate an instance if important work exists only on that root volume.

## Daily Workflow

A typical session looks like:

```bash
make instances
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make configure-ssh INSTANCE_NAME=dev
ssh ec2
make stop-instance INSTANCE_NAME=dev
```

Later:

```bash
make start-instance INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev
ssh ec2
```

When finished:

```bash
make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
```

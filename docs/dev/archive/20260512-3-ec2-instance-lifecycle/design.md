# Loop 3 Design: EC2 Instance Lifecycle

Started: 2026-05-12

## Goal

Design the EC2 instance lifecycle workflow for `banglab-aws-tools`.

This loop should let a lab member:

- list their current EC2 instances
- launch a new owner-tagged EC2 instance from an explicit recipe file
- inspect one instance
- SSH into a running instance
- stop, start, reboot, and terminate their own instances

This loop does not manage persistent EBS volumes. It only configures the root
EBS volume that EC2 creates with the instance.

## Prerequisites

The user should have completed:

```bash
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
make create-key
make import-key
make create-security-group
make add-ssh-rule SSH_RULE_NAME=home
```

The user should have:

```text
config.env
AWS key pair: <OWNER>-key
AWS security group: <OWNER>-ssh
at least one SSH inbound rule for their current location
```

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

- owner-tagged EC2 instance launch
- default VPC/subnet use
- key pair and security group reuse from Loop 2
- root EBS size selection at launch time
- listing owned instances
- status lookup by instance name
- SSH config generation for terminal SSH and VS Code Remote SSH
- start, stop, reboot, and terminate

Out of scope:

- persistent EBS volume creation
- attaching, detaching, formatting, or mounting extra EBS volumes
- AMI discovery
- quota management
- custom VPC support
- multi-instance clusters
- Spot instances
- IAM instance profiles
- automatic post-launch software setup

## Policy Constraints

The `EC2-GPU-Operator` permission set allows:

- EC2 describe actions
- `ec2:RunInstances` only when the request includes the user's own
  `Owner` tag
- `ec2:CreateTags` during `RunInstances` only with the user's own `Owner` tag
- `ec2:StartInstances`, `ec2:StopInstances`, `ec2:RebootInstances`, and
  `ec2:TerminateInstances` only for instances with the user's own `Owner`
  resource tag

Instances launched by the toolbox must include:

```text
Owner=<OWNER>
Name=<INSTANCE_NAME>
```

The toolbox should resolve instances by both `Owner` and `Name`, not by name
alone.

## Instance Recipe Files

Loop 3 should use explicit instance recipe files. The user should pass a recipe
when launching:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
```

The repo should include two committed recipes:

```text
instances/m7i-flex-xlarge.env
instances/g4dn-xlarge.env
```

Recipe files should be small and readable:

```bash
AMI_ID=ami-0252d9c82e6b8fa85
INSTANCE_TYPE=m7i-flex.xlarge
ROOT_VOLUME_SIZE_GB=200
```

and:

```bash
AMI_ID=ami-0252d9c82e6b8fa85
INSTANCE_TYPE=g4dn.xlarge
ROOT_VOLUME_SIZE_GB=200
```

There should be no `make init-instance-config` in this loop. Users can copy or
edit these small recipe files directly when they need a different instance type
or root volume size.

## Recommended AMI

Use this AMI in both initial recipes:

```text
Deep Learning Base AMI with Single CUDA (Ubuntu 22.04) 20260130
AMI ID: ami-0252d9c82e6b8fa85
```

This AMI is x86_64. Loop 3 should not use ARM/Graviton instance types with it.

## Root EBS Volume

The recipe should set:

```text
ROOT_VOLUME_SIZE_GB=200
```

Rationale:

- the root volume must hold the OS, Docker cache, package environments, cloned
  repos, and temporary working files
- this loop does not yet provide a separate persistent research EBS workflow
- 100 GB is reasonable for light use, but 200 GB is a safer first default for
  deep-learning AMIs and research workflows

The launch script should only configure the root volume size. It should not
create or attach persistent data volumes.

## User-Facing Docs To Design

This loop should draft and later promote:

```text
docs/ec2-instance-lifecycle.md
```

The doc should cover:

- what an instance recipe is
- recommended CPU and GPU recipes
- how to list current owned instances
- how to launch an instance
- how to check instance status
- how to update `~/.ssh/config` for an instance
- how to SSH into an instance using the generated host alias
- how to use the generated host alias with VS Code Remote SSH
- how to stop/start/reboot
- how to terminate with explicit confirmation
- the difference between stopping and terminating
- the warning that stopped instances may still have root EBS costs
- the warning that terminating deletes the instance and usually deletes its
  root EBS volume

## Planned Repo Structure For This Loop

```text
banglab-aws-tools/
├── docs/
│   └── ec2-instance-lifecycle.md
├── instances/
│   ├── m7i-flex-xlarge.env
│   └── g4dn-xlarge.env
└── scripts/
    └── ec2/
        ├── instances.sh
        ├── launch-instance.sh
        ├── instance-status.sh
        ├── configure-ssh.sh
        ├── stop-instance.sh
        ├── start-instance.sh
        ├── reboot-instance.sh
        └── terminate-instance.sh
```

Shared AWS helpers in `scripts/lib/aws.sh` should be extended rather than
duplicated.

## Proposed Make Targets

```bash
make instances
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make instance-status INSTANCE_NAME=dev
make configure-ssh INSTANCE_NAME=dev SSH_HOST=ec2
make stop-instance INSTANCE_NAME=dev
make start-instance INSTANCE_NAME=dev
make reboot-instance INSTANCE_NAME=dev
make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
```

Target behavior:

- `make instances`: list running, stopped, and recently terminated instances
  owned by the user
- `make launch-instance`: launch one owner-tagged instance from the required
  recipe file and wait until it reaches `running`
- `make instance-status`: show detailed status for one named owned instance
- `make configure-ssh`: update `~/.ssh/config` with a host alias for one
  running named owned instance
- `make stop-instance`: stop one named owned instance
- `make start-instance`: start one named owned instance
- `make reboot-instance`: reboot one named owned instance
- `make terminate-instance`: terminate one named owned instance only when
  `CONFIRM_TERMINATE` exactly matches `INSTANCE_NAME`

## Instance Naming

Users should provide an `INSTANCE_NAME` such as:

```text
dev
gpu-test
paper-exp
```

The toolbox should tag the instance:

```text
Owner=<OWNER>
Name=<INSTANCE_NAME>
```

The toolbox should search for instances using both tags:

```text
tag:Owner=<OWNER>
tag:Name=<INSTANCE_NAME>
```

If multiple non-terminated instances match the same `INSTANCE_NAME`, commands
should fail with a clear message and ask the user to resolve the duplicate.
Terminated instances should not count as duplicates for lifecycle commands.

## Instance Listing

`make instances` should be the daily entry point.

It should list running, pending, stopping, stopped, and recently terminated
instances owned by the user with compact per-instance blocks:

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

AWS retains terminated instance records for a while. Showing recently
terminated instances is useful after cleanup, but the docs should explain that
terminated records disappear from AWS after some time.

## Launch Defaults And Derived Values

Launch should derive these values from `config.env` and Loop 2 resources:

```text
KEY_NAME=<OWNER>-key
SECURITY_GROUP_NAME=<OWNER>-ssh
DEFAULT_AVAILABILITY_ZONE=us-east-1a
```

The launch script should:

1. load `config.env`
2. load `INSTANCE_CONFIG`
3. validate `AMI_ID`, `INSTANCE_TYPE`, and `ROOT_VOLUME_SIZE_GB`
4. find the default VPC
5. find a subnet in `DEFAULT_AVAILABILITY_ZONE`
6. verify the key pair exists and has `Owner=<OWNER>`
7. verify the security group exists and has `Owner=<OWNER>`
8. launch the instance with `Owner` and `Name` tags
9. set the root EBS size from `ROOT_VOLUME_SIZE_GB`
10. print the new instance ID
11. wait until the instance reaches `running`, printing a simple progress
    message such as `pending...`
12. print the public IP and next commands
13. remind the user that SSH may take another 30-60 seconds to become ready

All launch settings should come from `INSTANCE_CONFIG`. Loop 3 should not
support command-line overrides for `AMI_ID`, `INSTANCE_TYPE`, or
`ROOT_VOLUME_SIZE_GB`.

## SSH Config Behavior

The user currently expects a workflow like:

```sshconfig
Host ec2
  HostName 44.214.107.98
  User ubuntu
  IdentityFile ~/.ssh/banglab
```

Then they can run:

```bash
ssh ec2
```

and use the same `ec2` host from VS Code Remote SSH.

Loop 3 should support this directly.

`make configure-ssh INSTANCE_NAME=dev SSH_HOST=ec2` should:

- resolve the named owned instance
- require it to be `running`
- require a public IP
- update `~/.ssh/config`
- set `Host` to `SSH_HOST`
- set `HostName` to the instance public IP
- set `User` to `ubuntu`
- set `IdentityFile` to `SSH_KEY_PATH`
- print `ssh ec2` as the next command

The command should manage a clearly marked block so repeated runs replace the
old entry instead of appending duplicates:

```sshconfig
# banglab-aws-tools begin ec2
Host ec2
  HostName 44.214.107.98
  User ubuntu
  IdentityFile /Users/songxiran/.ssh/takishiina
  IdentitiesOnly yes
# banglab-aws-tools end ec2
```

If `SSH_HOST` already exists outside a managed block, the command should fail
clearly and ask the user to remove the old entry or choose another host alias.

`SSH_HOST` should default to:

```text
ec2
```

Users can override it when they want names such as:

```text
ec2
dev
gpu
paper-exp
```

When an instance is stopped and started again, its public IP may change. The
user should rerun:

```bash
make configure-ssh INSTANCE_NAME=dev SSH_HOST=ec2
```

The docs should explain that this refreshes both terminal SSH and VS Code
Remote SSH.

## SSH Usage

The toolbox should not wrap normal SSH after `~/.ssh/config` is updated.
Users should connect with standard tools:

```bash
ssh ec2
```

or choose the same host alias in VS Code Remote SSH.

## Lifecycle Safety

Stopping:

- should be allowed for owned instances
- should print a reminder that root EBS may still cost money

Starting:

- should be allowed for owned instances
- should remind the user that the public IP may change after stop/start
- should remind the user to rerun `make configure-ssh` after the instance is
  running
- should tolerate a brief stale `stopped` state after AWS accepts the start
  request

Rebooting:

- should be allowed for owned running instances

Terminating:

- should require explicit confirmation:

```bash
make terminate-instance INSTANCE_NAME=dev CONFIRM_TERMINATE=dev
```

- should refuse to run if confirmation is missing or different
- should warn that termination deletes the EC2 instance and usually deletes the
  root EBS volume

## Settled Design Decisions

- `launch-instance` should wait until the instance reaches `running`.
- `configure-ssh` should use the instance public IP as `HostName`.
- `instances` should show running, stopped, and recently terminated instances.
- Launch settings should come from `INSTANCE_CONFIG`; command-line overrides are
  out of scope for Loop 3.
- The default suggested `SSH_HOST` should be `ec2`.

## Done Criteria

This loop is done when:

- `docs/ec2-instance-lifecycle.md` is drafted and reviewed
- command/API shape is documented
- instance recipe files are added
- Make targets are implemented
- EC2 lifecycle scripts are implemented
- commands work with the Taki test profile
- `status_and_plan.md` is updated
- loop docs are archived according to `docs/dev/README.md`

## Loop Todo

1. Draft design doc: done
   - `docs/dev/loop/design.md`

2. Resolve open questions: done

3. Draft user-facing docs: done
   - `docs/ec2-instance-lifecycle.md`

4. Draft command/API docs: done
   - `docs/dev/loop/api.md`

5. Add instance recipe files: done
   - `instances/m7i-flex-xlarge.env`
   - `instances/g4dn-xlarge.env`

6. Add Make targets: done
   - `instances`
   - `launch-instance`
   - `instance-status`
   - `configure-ssh`
   - `stop-instance`
   - `start-instance`
   - `reboot-instance`
   - `terminate-instance`

7. Implement EC2 lifecycle scripts: done

8. Verify with test user assumptions

9. Close and archive Loop 3

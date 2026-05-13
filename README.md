# BangLab AWS Tools

`banglab-aws-tools` is a small command-line toolbox for BangLab research
workflows on AWS.

It starts after AWS Access Portal onboarding. A lab member should already be
able to log in to the BangLab AWS Access Portal, select an AWS account, and use
the `EC2-GPU-Operator` permission set.

The core model is:

```text
EC2 instances are disposable.
Persistent research state lives on EBS at ~/scratch.
AWS resources are separated with Owner=<username> tags.
```

## What This Toolbox Supports

- local AWS CLI SSO setup and identity verification
- SSH key pair and security group setup
- EC2 instance launch, status, stop, start, reboot, and terminate
- persistent EBS volume creation, attach, one-time setup, and daily mount
- GitHub SSH key and dotfile persistence on EBS
- micromamba installation on EBS

## Quick Walkthrough

Start with the user guide:

```text
docs/README.md
```

Typical order:

1. Read `docs/prerequisites.md`.
2. Run local setup in `docs/local-machine-setup.md`.
3. Set up SSH access in `docs/ssh-access-setup.md`.
4. Launch and manage EC2 instances with `docs/ec2-instance-lifecycle.md`.
5. Create and mount persistent storage with `docs/persistent-ebs.md`.
6. Set up GitHub and dotfile persistence with `docs/github-and-dotfiles.md`.
7. Install micromamba with `docs/micromamba-setup.md`.

## Common Commands

```bash
make help
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
make ssh-status
make instances
make volumes
```

Launch a CPU instance:

```bash
make launch-instance INSTANCE_NAME=dev INSTANCE_CONFIG=instances/m7i-flex-xlarge.env
make configure-ssh INSTANCE_NAME=dev
ssh ec2
```

Attach persistent EBS from your local laptop:

```bash
make attach-volume VOLUME_ID=vol-0123456789abcdef0 INSTANCE_NAME=dev
```

Mount it inside the EC2 instance:

```bash
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

## Notes

- This toolbox uses the default VPC in `us-east-1`.
- Use full BangLab usernames for `OWNER`, such as `takishiina`.
- The toolbox is intentionally focused on EC2, EBS, SSH, GitHub dotfiles, and
  micromamba.

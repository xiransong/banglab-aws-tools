# BangLab AWS Tools

`banglab-aws-tools` is a small toolbox for BangLab research workflows on AWS.
It is designed for lab members who have already completed AWS Access Portal
login and can select an AWS account with the `EC2-GPU-Operator` permission set.

The toolbox will focus on practical EC2, EBS, S3, and environment setup tasks:

- configure and verify local AWS CLI access
- check current EC2 instance and EBS volume status
- create and initialize a persistent EBS workspace mounted at `~/scratch`
- launch, stop, start, and terminate CPU or GPU EC2 instances
- attach, detach, and mount persistent EBS volumes
- optionally set up GitHub, micromamba, Node.js, Codex, and other research tools

The core mental model is:

```text
EC2 instances are disposable.
Persistent research state lives on EBS at ~/scratch.
Resources are isolated with Owner=<username> tags.
```

## Current Status

Loop 1 is complete: local machine setup.

Implemented commands:

```bash
make help
make init-config
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
```

Start with:

```text
docs/prerequisites.md
docs/local-machine-setup.md
```

## Planned Structure

```text
banglab-aws-tools/
├── README.md
├── Makefile
├── config.example.env
├── docs/
│   ├── prerequisites.md
│   ├── local-machine-setup.md
│   ├── workflows.md
│   ├── persistent-ebs.md
│   ├── daily-ec2-workflow.md
│   └── optional-tools.md
└── scripts/
    ├── lib/
    ├── local/
    ├── status/
    ├── ec2/
    ├── ebs/
    ├── s3/
    └── optional/
```

## Prerequisite

Before using this toolbox, complete the AWS Access Portal onboarding process.
For example, a user such as Taki Shiina would first verify that she can log in
as `takishiina`, select the target AWS account, and use the
`EC2-GPU-Operator` permission set.

After that, this toolbox can guide the remaining setup and daily workflows.

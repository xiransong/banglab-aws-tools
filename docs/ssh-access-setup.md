# SSH Access Setup

This page prepares SSH access for future EC2 instances.

Before starting, complete local machine setup:

```bash
make doctor
make configure-aws-sso
make aws-login
make aws-whoami
```

This workflow creates:

```text
local private key: ~/.ssh/<OWNER>
local public key: ~/.ssh/<OWNER>.pub
AWS key pair: <OWNER>-key
AWS security group: <OWNER>-ssh
```

For Taki Shiina:

```text
local private key: ~/.ssh/takishiina
local public key: ~/.ssh/takishiina.pub
AWS key pair: takishiina-key
AWS security group: takishiina-ssh
```

## What This Setup Does

SSH access has two parts:

- an **SSH key pair**, which proves that your laptop is allowed to connect
- a **security group**, which allows network traffic to reach the instance

The private key stays on your laptop. AWS only receives the public key.

## Ownership Rules

The toolbox uses your `OWNER` value from `config.env`.

Key pairs are imported with:

```text
Owner=<OWNER>
Name=<OWNER>-key
```

Security groups are created with:

```text
Owner=<OWNER>
Name=<OWNER>-ssh
```

The current permission set enforces owner tags for both key pairs and security
groups. The toolbox creates or imports these AWS resources with `Owner` and
`Name` tags, and it should not silently create untagged resources.

## Step 1: Check SSH Setup Status

Run:

```bash
make ssh-status
```

This should report:

- whether the local private key exists
- whether the local public key exists
- whether the AWS key pair exists
- whether the AWS key pair has the expected `Owner` tag
- whether the default VPC exists
- whether the security group exists
- whether the security group has the expected `Owner` tag
- which SSH inbound rules are currently configured

## Step 2: Create a Local SSH Key

Run:

```bash
make create-key
```

This creates:

```text
~/.ssh/<OWNER>
~/.ssh/<OWNER>.pub
```

The command should refuse to overwrite an existing key.

## Step 3: Import the Public Key to AWS

Run:

```bash
make import-key
```

This imports:

```text
~/.ssh/<OWNER>.pub
```

as:

```text
<OWNER>-key
```

The AWS key pair should be tagged with `Owner` and `Name`. If a key pair with
the same name already exists, the command checks that its `Owner` tag matches
your `OWNER` value.

## Step 4: Create Your SSH Security Group

Run:

```bash
make create-security-group
```

This creates a security group in the default VPC:

```text
<OWNER>-ssh
```

The security group should be tagged with `Owner` and `Name`.

If the account has no default VPC, the command should stop and explain the
problem.

## Step 5: Add an SSH Rule for Your Current Location

Run:

```bash
make add-ssh-rule SSH_RULE_NAME=home
```

The toolbox detects your current public IP address and adds an SSH inbound rule:

```text
TCP 22 from <current-public-ip>/32
```

The rule description is:

```text
<OWNER>-<SSH_RULE_NAME>
```

Examples:

```bash
make add-ssh-rule SSH_RULE_NAME=home
make add-ssh-rule SSH_RULE_NAME=lab
```

This lets you keep separate rules for different places. The command should not
remove old rules automatically.

## Step 6: Check Status Again

Run:

```bash
make ssh-status
```

You should now see:

- local key files present
- AWS key pair present
- security group present
- at least one SSH rule for your current location

## Later EC2 Workflows

Future EC2 launch commands will use:

```text
KEY_NAME=<OWNER>-key
SECURITY_GROUP_NAME=<OWNER>-ssh
```

The SSH command will look like:

```bash
ssh -i ~/.ssh/<OWNER> ubuntu@<PUBLIC_IP>
```

For Taki:

```bash
ssh -i ~/.ssh/takishiina ubuntu@<PUBLIC_IP>
```

## What This Setup Does Not Do

This page does not:

- launch EC2 instances
- create EBS volumes
- mount EBS volumes
- set up GitHub, micromamba, Node.js, or Codex
- delete key pairs or security groups
- revoke old SSH rules

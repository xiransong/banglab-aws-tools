# Prerequisites

Before using `banglab-aws-tools`, make sure your local machine and AWS access
are ready.

This toolbox starts after AWS Access Portal onboarding. It does not replace
password setup, MFA setup, or AWS Access Portal login.

## 1. AWS Access Portal Login Is Complete

You should be able to:

- open the BangLab AWS Access Portal (https://banglab-udem-mila.awsapps.com/start)
- log in with MFA
- select an AWS account
- select the `EC2-GPU-Operator` permission set
- open the AWS Console

For example, the test user Taki Shiina should be able to log in as:

```text
Username / Owner: takishiina
AWS account: xiransong
Permission set: EC2-GPU-Operator
```

## 2. You Have a Supported Terminal

Supported in the first version:

- macOS Terminal or iTerm
- Linux shell
- Windows via WSL2 Ubuntu

Not supported in the first version:

- native Windows PowerShell
- native Windows CMD

The toolbox assumes a Unix-like terminal.

## 3. AWS CLI v2 Is Installed

Check:

```bash
aws --version
```

Expected output should begin with:

```text
aws-cli/2
```

If `aws` is missing or reports AWS CLI v1, install AWS CLI v2 before
continuing (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

## 4. Required CLI Tools Are Installed

Check:

```bash
make --version
git --version
ssh -V
curl --version
jq --version
```

These tools are used by local setup and later AWS workflow scripts.

## 5. You Know Your BangLab Username

Your BangLab username is the value used for AWS ownership rules.

Example:

```text
Taki Shiina -> takishiina
```

Later AWS resources should use this value:

```text
Owner=takishiina
Name=takishiina-...
```

## 6. You Know Your AWS Account ID

The AWS CLI SSO profile needs the 12-digit AWS account ID.

You can copy the account ID from the AWS Access Portal.

For the current test account:

```text
AWS account label: xiransong
AWS account ID: 777712053059
```

The account label is for humans. The account ID is what AWS CLI needs.

## Next Step

After this checklist passes, continue to:

```text
docs/local-machine-setup.md
```

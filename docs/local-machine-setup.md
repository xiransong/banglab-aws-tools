# Local Machine Setup

This page sets up your local machine to use `banglab-aws-tools`.

Before starting, complete the checklist in:

```text
docs/prerequisites.md
```

## Step 1: Create Local Config

Clone this repo:

```bash
git clone https://github.com/xiransong/banglab-aws-tools.git
cd banglab-aws-tools
```

From the repo root:

```bash
make init-config
```

This creates:

```text
config.env
```

The command should refuse to overwrite an existing `config.env`.
It also prints a config summary and an action prompt showing which fields must
be changed before continuing.

## Step 2: Edit `config.env`

Open `config.env` and fill in your values.

Only these fields are user-specific and must be checked or changed:

```bash
OWNER=takishiina
AWS_PROFILE=takishiina
AWS_ACCOUNT_LABEL=xiransong
AWS_ACCOUNT_ID=777712053059
AWS_SSO_SESSION=banglab-takishiina
```

For Taki Shiina, `OWNER` is `takishiina`. She is testing in the `xiransong`
AWS account, whose account ID is `777712053059`.

The remaining fields are BangLab defaults for this toolbox:

```bash
AWS_REGION=us-east-1
AWS_SSO_START_URL=https://banglab-udem-mila.awsapps.com/start
AWS_SSO_REGION=us-east-1
AWS_SSO_ROLE_NAME=EC2-GPU-Operator
DEFAULT_AVAILABILITY_ZONE=us-east-1a
```

A complete test config would look like:

```bash
OWNER=takishiina
AWS_PROFILE=takishiina
AWS_REGION=us-east-1
AWS_ACCOUNT_LABEL=xiransong
AWS_ACCOUNT_ID=777712053059
AWS_SSO_SESSION=banglab-takishiina
AWS_SSO_START_URL=https://banglab-udem-mila.awsapps.com/start
AWS_SSO_REGION=us-east-1
AWS_SSO_ROLE_NAME=EC2-GPU-Operator
DEFAULT_AVAILABILITY_ZONE=us-east-1a
```

**Important**:

- `OWNER` is your BangLab username and will be used for AWS resource ownership.
- `AWS_PROFILE` is the local AWS CLI profile name.
- `AWS_ACCOUNT_LABEL` is a human-readable account label.
- `AWS_ACCOUNT_ID` is the 12-digit AWS account ID copied from AWS Access
  Portal.
- `AWS_SSO_SESSION` is the local AWS CLI SSO cache name. Use different values
  for different AWS users on the same laptop, such as `banglab-takishiina`.

## Step 3: Check Local Readiness

Run:

```bash
make doctor
```

This checks local configuration and required CLI tools.
It also prints the same config summary, which is useful for catching mistakes
before generating the AWS CLI profile.

`make doctor` is intentionally simple. It should not log in to AWS, create AWS
profiles, or provision AWS resources.

## Step 4: Configure AWS CLI SSO Profile

Run:

```bash
make configure-aws-sso
```

This creates or updates the AWS CLI profile in:

```text
~/.aws/config
```

If the file already exists, the command creates a timestamped backup before
rewriting the matching profile and SSO session sections.

The generated profile should look like:

```ini
[profile takishiina]
sso_session = banglab-takishiina
sso_account_id = 777712053059
sso_role_name = EC2-GPU-Operator
region = us-east-1
output = json

[sso-session banglab-takishiina]
sso_start_url = https://banglab-udem-mila.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

This avoids the full interactive `aws configure sso` prompt sequence.

## Step 5: Log In To AWS

Run:

```bash
make aws-login
```

A browser window should open. Log in through the BangLab AWS Access Portal and
complete MFA if prompted.

If you use multiple AWS users on the same laptop, make sure the browser is
logged in as the same person as `OWNER`. If AWS CLI keeps reusing the wrong
identity, run:

```bash
aws sso logout
make aws-login
```

You may also need to sign out of the AWS Access Portal in the browser, then log
in again as the intended user.

## Step 6: Verify AWS CLI Identity

Run:

```bash
make aws-whoami
```

This should call AWS STS using your configured profile and show the account and
assumed role.

Example successful output:

```json
{
  "UserId": "AROA3KE2AFNBWPZVNB7UB:takishiina",
  "Account": "777712053059",
  "Arn": "arn:aws:sts::777712053059:assumed-role/AWSReservedSSO_EC2-GPU-Operator_0c66aaf5e2f86c0b/takishiina"
}
```

A successful result means:

- AWS CLI is installed
- your SSO profile is configured
- login works
- the CLI can assume `EC2-GPU-Operator`

Check that:

- `Account` matches the AWS account ID in `config.env`
- `Arn` contains `EC2-GPU-Operator`
- `Arn` ends with your username

`make aws-whoami` fails if the account, role, or final username in the ARN does
not match `config.env`. This catches a common multi-user laptop mistake: using a
profile named for one user while AWS CLI is still logged in as another user.

## Next Step

This page does not create AWS resources. After local setup, continue to:

```text
docs/ssh-access-setup.md
```

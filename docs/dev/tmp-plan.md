# Cleanup Todo

This is a lightweight cleanup plan. Do not create a formal loop for this phase.

## Goal

Make `banglab-aws-tools` feel stable, concise, and easy for lab members to
follow. Then update `banglab-aws-docs` so it points to the tools repo instead
of duplicating detailed EC2 workflows.

## `banglab-aws-tools`

### 1. Light Code Cleanup

- [x] Rename development-oriented helper names in shell scripts.
- [x] Use product/workflow names instead, for example:
      `validate_local_config`, `validate_ssh_config`, `validate_ec2_config`,
      `validate_ebs_config`.
- [x] Keep the refactor mechanical and low-risk.
- [x] Add simple colored log prefixes in `scripts/lib/log.sh` if output is a
      terminal.
- [x] Do not add new user-facing features during this cleanup.

### 2. User-Facing Docs Cleanup

- [x] Treat everything outside `docs/dev` as user-facing.
- [x] Remove development wording such as "loop" from user-facing docs.
- [x] Make sure user-facing docs accurately reflect current supported features.
- [x] Remove or soften stale future-work claims such as S3 or Codex support.

### 3. Add AWS Console Guidance

- [x] Add a repo-level framing section:
      - `banglab-aws-tools` is a toolbox plus workflow guide
      - CLI commands are best for reproducible setup and tag-sensitive actions
      - AWS Console is best for review, inspection, and simple manual operations
- [x] Create `docs/assets/images/`.
- [x] Copy selected screenshots from `banglab-aws-docs/docs/assets/images/`:
      - `aws-console.png`
      - `aws-instance-ip-address.png`
      - `aws-instance-state.png`
      - `aws-key-pair.png`
      - `aws-security-group-inbound-rules.png`
- [x] Add only a small number of screenshots at first. Add more later if users
      get stuck.
- [x] Add AWS Console guidance to `docs/ec2-instance-lifecycle.md`:
      - open AWS Console through AWS Access Portal
      - select region `us-east-1`
      - go to **EC2 -> Instances**
      - review instance state
      - copy public IPv4 address
      - stop/start/terminate owned instances
      - use tags `Owner=<username>` and `Name=<instance name>` to identify
        resources
- [x] Add AWS Console guidance to `docs/persistent-ebs.md`:
      - go to **EC2 -> Volumes**
      - review volume state
      - review size and availability zone
      - check attachment status
      - distinguish root volumes from persistent scratch volumes
      - use tags `Owner=<username>` and `Name=<volume name>` to identify
        resources
- [x] Add AWS Console guidance to `docs/ssh-access-setup.md`:
      - go to **EC2 -> Key Pairs**
      - go to **EC2 -> Security Groups**
      - inspect inbound SSH rules
      - explain that CLI remains the recommended way to create/import these
        resources because it applies the expected tags
- [x] Avoid turning the Console notes into a second full tutorial.
- [x] Keep CLI as the primary reproducible workflow.

### 4. Doc Entry Point Cleanup

- [x] Rewrite the repo-level `README.md` as the concise main walkthrough.
- [x] Make `docs/README.md` a clean user-guide index.

### 5. Current Feature List To Reflect

- [x] Local machine setup
- [x] AWS SSO profile setup and identity verification
- [x] SSH key pair and security group setup
- [x] EC2 instance lifecycle
- [x] Persistent EBS creation, attach, setup, and mount
- [x] GitHub SSH key and dotfile persistence
- [x] Micromamba installation on persistent EBS

## `banglab-aws-docs`

Do this after `banglab-aws-tools` is cleaned up.

- [ ] Add `docs/ec2/recommended-ami-and-instance.md` to the docs index/nav.
- [ ] Adjust EC2 docs so conceptual/onboarding material stays in
      `banglab-aws-docs`.
- [ ] Point practical EC2 workflows to `banglab-aws-tools`.
- [ ] Retire or simplify old EC2 pages that duplicate the tools repo.
- [ ] Keep `banglab-aws-docs` as the conceptual guide and onboarding site.
- [ ] Keep `banglab-aws-tools` as the practical command reference.

## Publishing

- [ ] After both repos are cleaned up, review for sensitive information.
- [ ] If clean, make the repos public.
- [ ] Publish `banglab-aws-docs` with GitHub Pages.

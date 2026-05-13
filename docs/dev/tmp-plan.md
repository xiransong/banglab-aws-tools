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

- [ ] Treat everything outside `docs/dev` as user-facing.
- [ ] Remove development wording such as "loop" from user-facing docs.
- [ ] Make sure user-facing docs accurately reflect current supported features.
- [ ] Remove or soften stale future-work claims such as S3 or Codex support.

### 3. Add AWS Console Guidance

- [ ] Add AWS Console guidance where helpful:
      - check running instances
      - check public IP
      - check EBS volumes
      - stop/start/terminate instances
- [ ] Keep CLI as the primary reproducible workflow, but mention the Console as
      a useful review interface.

### 4. Doc Entry Point Cleanup

- [ ] Rewrite the repo-level `README.md` as the concise main walkthrough.
- [ ] Make `docs/README.md` a clean user-guide index.

### 5. Current Feature List To Reflect

- [ ] Local machine setup
- [ ] AWS SSO profile setup and identity verification
- [ ] SSH key pair and security group setup
- [ ] EC2 instance lifecycle
- [ ] Persistent EBS creation, attach, setup, and mount
- [ ] GitHub SSH key and dotfile persistence
- [ ] Micromamba installation on persistent EBS

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

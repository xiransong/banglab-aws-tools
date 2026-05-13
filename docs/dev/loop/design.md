# Loop 5 Design: GitHub And Dotfile Persistence

Started: 2026-05-12

## Goal

Design a simple inside-instance workflow for GitHub SSH setup and dotfile
persistence.

This loop should let a lab member:

- generate a GitHub SSH key manually inside an EC2 instance
- add the public key to their GitHub account manually
- save useful dotfiles and SSH key files to persistent EBS
- restore those files on a new disposable EC2 instance

This loop should stay deliberately simple. It should follow the proven pattern
from the older `MyAWS` scripts:

```text
copy files from home directory to ~/scratch/dotfiles
copy files from ~/scratch/dotfiles back to home directory
```

## Workflow Shape

One-time GitHub SSH setup:

```bash
# inside EC2 instance, after ~/scratch is mounted
ssh-keygen -t ed25519 -C "your_email@example.com"
```

The command is interactive because `ssh-keygen` asks where to save the key and
whether to use a passphrase. Users should accept the default path:

```text
~/.ssh/id_ed25519
```

The user then prints the public key and adds it to GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
```

```text
https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account
```

One-time save to persistent EBS:

```bash
make save-dotfiles
```

Daily or new-instance restore:

```bash
make mount-scratch VOLUME_ID=vol-...
make restore-dotfiles
```

## Prerequisites

This loop runs inside an EC2 instance.

The user should already have:

- launched or started an EC2 instance
- configured SSH from the local laptop
- SSHed into the instance
- mounted persistent EBS at `~/scratch`
- generated a GitHub SSH key if they want GitHub SSH persistence

The commands in this loop should not call AWS APIs.

## Scope

In scope:

- document the manual GitHub SSH-key generation step
- document how to add the public key to GitHub
- save selected dotfiles from `~/` to `~/scratch/dotfiles`
- restore selected dotfiles from `~/scratch/dotfiles` to `~/`
- preserve SSH key permissions
- warn clearly that a private key is being stored on persistent EBS

Out of scope:

- GitHub API calls
- GitHub CLI setup
- `ssh -T git@github.com` test command
- automatic browser flows
- automatic GitHub public-key upload
- Git commit signing keys
- advanced dotfile frameworks
- symlink-based dotfile management
- full home-directory persistence
- encrypted secret stores
- multi-key SSH config management

## Dotfile Layout

Persistent EBS source of truth:

```text
~/scratch/dotfiles/
├── bashrc
├── gitconfig
├── texlive-env
└── ssh/
    ├── id_ed25519
    └── id_ed25519.pub
```

Disposable home directory targets:

```text
~/.bashrc
~/.gitconfig
~/.texlive-env
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

## Why Copy Instead Of Symlink

Use plain copies for this loop.

Reasons:

- easy to understand
- easy to inspect
- robust on disposable instances
- matches the old working scripts
- avoids confusing partial home-directory persistence

The tradeoff is that users must run `make save-dotfiles` after changing a file
they want to preserve.

## Security Framing

The GitHub private key is sensitive.

This loop intentionally stores the private key on persistent EBS because that is
the durable research workspace. The docs and scripts should say this plainly.

Expected safeguards:

- persistent EBS access is controlled by AWS owner-tag permissions
- `~/scratch/dotfiles/ssh` should be `700`
- private key should be `600`
- public key should be `644`
- users should use one GitHub key per user, not a shared lab key
- users should not commit private keys to any repository

## Planned User Commands

Inside-instance commands:

```bash
make save-dotfiles
make restore-dotfiles
```

### `make save-dotfiles`

Purpose: save selected files from the disposable home directory to persistent
EBS.

Expected behavior:

- require `~/scratch` to exist and be mounted
- create `~/scratch/dotfiles`
- create `~/scratch/dotfiles/ssh`
- copy `~/.bashrc` to `~/scratch/dotfiles/bashrc` if present
- copy `~/.gitconfig` to `~/scratch/dotfiles/gitconfig` if present
- copy `~/.texlive-env` to `~/scratch/dotfiles/texlive-env` if present
- copy `~/.ssh/id_ed25519` to `~/scratch/dotfiles/ssh/id_ed25519` if present
- copy `~/.ssh/id_ed25519.pub` to `~/scratch/dotfiles/ssh/id_ed25519.pub` if
  present
- warn for missing optional files
- overwrite existing files in `~/scratch/dotfiles`
- set conservative permissions
- print a summary

Expected permissions:

```text
~/scratch/dotfiles              700
~/scratch/dotfiles/ssh          700
~/scratch/dotfiles/bashrc       644
~/scratch/dotfiles/gitconfig    644
~/scratch/dotfiles/texlive-env  644
~/scratch/dotfiles/ssh/id_ed25519      600
~/scratch/dotfiles/ssh/id_ed25519.pub  644
```

### `make restore-dotfiles`

Purpose: restore selected files from persistent EBS to the disposable home
directory.

Expected behavior:

- require `~/scratch` to exist and be mounted
- read from `~/scratch/dotfiles`
- restore `~/scratch/dotfiles/bashrc` to `~/.bashrc` if present
- restore `~/scratch/dotfiles/gitconfig` to `~/.gitconfig` if present
- restore `~/scratch/dotfiles/texlive-env` to `~/.texlive-env` if present
- create `~/.ssh`
- restore `~/scratch/dotfiles/ssh/id_ed25519` to `~/.ssh/id_ed25519` if present
- restore `~/scratch/dotfiles/ssh/id_ed25519.pub` to
  `~/.ssh/id_ed25519.pub` if present
- warn for missing optional files
- overwrite existing target files in `~/`
- set conservative permissions
- print next steps

Expected next steps:

```bash
source ~/.bashrc
```

Do not run `ssh -T git@github.com` automatically.

## User-Facing Docs To Draft

This loop should draft:

```text
docs/github-and-dotfiles.md
```

The doc should cover:

- this workflow runs inside the EC2 instance
- `~/scratch` must already be mounted
- how to manually generate an Ed25519 GitHub SSH key
- how to print the public key
- where to add the public key in GitHub
- what `save-dotfiles` saves
- what `restore-dotfiles` restores
- why the private key is stored on persistent EBS
- why this loop uses copies rather than symlinks

## Planned Repo Structure

```text
banglab-aws-tools/
├── docs/
│   └── github-and-dotfiles.md
└── scripts/
    └── remote/
        ├── save-dotfiles.sh
        └── restore-dotfiles.sh
```

The scripts can reuse `scripts/lib/log.sh`. They should not need AWS helpers.

## Open Questions

Resolved:

1. Include `~/.gitconfig` in Loop 5.
2. Keep the SSH filename fixed as `id_ed25519`, matching GitHub's common
   default.
3. `save-dotfiles` should overwrite existing files in `~/scratch/dotfiles`
   without a confirmation prompt.
4. `restore-dotfiles` should overwrite existing files in `~/` without a
   confirmation prompt.
5. Do not add a key-generation Make target. The docs should tell users to run
   `ssh-keygen -t ed25519 -C "your_email@example.com"` directly and accept the
   default `~/.ssh/id_ed25519` path.

## Done Criteria

This loop is done when:

- `docs/dev/loop/design.md` is reviewed
- `docs/github-and-dotfiles.md` is drafted
- command/API docs are drafted
- Make targets are implemented
- `save-dotfiles` and `restore-dotfiles` are implemented
- scripts are tested on an EC2 instance with mounted `~/scratch`
- `status_and_plan.md` is updated
- loop docs are archived according to `docs/dev/README.md`

## Loop Todo

1. Draft design doc: done
   - `docs/dev/loop/design.md`

2. Resolve open questions: done

3. Draft user-facing docs: done
   - `docs/github-and-dotfiles.md`

4. Draft command/API docs: done
   - `docs/dev/loop/api.md`

5. Add Make targets: done
   - `save-dotfiles`
   - `restore-dotfiles`

6. Implement remote dotfile scripts: done
   - `scripts/remote/save-dotfiles.sh`
   - `scripts/remote/restore-dotfiles.sh`

7. Verify inside an EC2 instance with mounted `~/scratch`

8. Close and archive Loop 5

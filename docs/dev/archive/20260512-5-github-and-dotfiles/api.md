# Loop 5 API: GitHub And Dotfile Persistence

This document defines the command interface for Loop 5 before implementation.

All commands in this loop run inside an EC2 instance. They do not call AWS APIs.

## User Commands

```bash
make save-dotfiles
make restore-dotfiles
```

## Shared Assumptions

The user has already mounted persistent EBS at:

```text
~/scratch
```

Persistent dotfiles live under:

```text
~/scratch/dotfiles
```

The commands should use fixed paths:

```text
SCRATCH=${HOME}/scratch
DOTFILES=${HOME}/scratch/dotfiles
SSH_DOTFILES=${HOME}/scratch/dotfiles/ssh
```

## `make save-dotfiles`

Purpose: save selected home-directory files to persistent EBS.

Expected behavior:

- require `~/scratch` to be mounted
- create `~/scratch/dotfiles`
- create `~/scratch/dotfiles/ssh`
- copy available files:

```text
~/.bashrc              -> ~/scratch/dotfiles/bashrc
~/.gitconfig           -> ~/scratch/dotfiles/gitconfig
~/.texlive-env         -> ~/scratch/dotfiles/texlive-env
~/.ssh/id_ed25519      -> ~/scratch/dotfiles/ssh/id_ed25519
~/.ssh/id_ed25519.pub  -> ~/scratch/dotfiles/ssh/id_ed25519.pub
```

- warn when optional source files are missing
- overwrite existing files under `~/scratch/dotfiles`
- set permissions:

```text
~/scratch/dotfiles                       700
~/scratch/dotfiles/ssh                   700
~/scratch/dotfiles/bashrc                644
~/scratch/dotfiles/gitconfig             644
~/scratch/dotfiles/texlive-env           644
~/scratch/dotfiles/ssh/id_ed25519        600
~/scratch/dotfiles/ssh/id_ed25519.pub    644
```

- print a summary
- warn that the private key is stored on persistent EBS

## `make restore-dotfiles`

Purpose: restore selected files from persistent EBS to the disposable home
directory.

Expected behavior:

- require `~/scratch` to be mounted
- read from `~/scratch/dotfiles`
- create `~/.ssh`
- copy available files:

```text
~/scratch/dotfiles/bashrc                -> ~/.bashrc
~/scratch/dotfiles/gitconfig             -> ~/.gitconfig
~/scratch/dotfiles/texlive-env           -> ~/.texlive-env
~/scratch/dotfiles/ssh/id_ed25519        -> ~/.ssh/id_ed25519
~/scratch/dotfiles/ssh/id_ed25519.pub    -> ~/.ssh/id_ed25519.pub
```

- warn when optional persistent files are missing
- overwrite existing target files under `~/`
- set permissions:

```text
~/.ssh             700
~/.bashrc          644
~/.gitconfig       644
~/.texlive-env     644
~/.ssh/id_ed25519      600
~/.ssh/id_ed25519.pub  644
```

- print next step:

```bash
source ~/.bashrc
```

This command should not run `ssh -T git@github.com`.

## Script Mapping

```text
make save-dotfiles     -> scripts/remote/save-dotfiles.sh
make restore-dotfiles  -> scripts/remote/restore-dotfiles.sh
```

Shared helpers:

```text
scripts/lib/log.sh
```

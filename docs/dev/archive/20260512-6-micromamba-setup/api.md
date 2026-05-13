# Loop 6 API: Micromamba Setup

This document defines the command interface for Loop 6 before implementation.

All commands in this loop run inside an EC2 instance. They do not call AWS APIs.

## User Commands

```bash
make install-micromamba
```

## Shared Assumptions

The user has already mounted persistent EBS at:

```text
~/scratch
```

Micromamba should be installed under:

```text
~/scratch/micromamba
```

Fixed paths:

```text
MAMBA_ROOT_PREFIX=${HOME}/scratch/micromamba
MICROMAMBA_BIN=${HOME}/scratch/micromamba/bin/micromamba
```

## `make install-micromamba`

Purpose: install micromamba into persistent EBS and enable it in bash.

Expected behavior:

- require `~/scratch` to be mounted
- check that `curl` exists
- check that `tar` exists
- set `MAMBA_ROOT_PREFIX=${HOME}/scratch/micromamba`
- set `MICROMAMBA_BIN=${HOME}/scratch/micromamba/bin/micromamba`
- if `MICROMAMBA_BIN` already exists and is executable:
  - print the existing path
  - print `MICROMAMBA_BIN --version`
  - skip download and extraction
  - still ensure the bash hook exists
- create `~/scratch/micromamba/bin`
- download:

```text
https://micro.mamba.pm/api/micromamba/linux-64/latest
```

- extract the tarball into a temporary directory
- copy `bin/micromamba` into `MICROMAMBA_BIN`
- set executable permissions
- generate the micromamba bash hook with:

```bash
"${MICROMAMBA_BIN}" shell hook \
  --shell bash \
  --root-prefix "${MAMBA_ROOT_PREFIX}"
```

- append an idempotent managed block to `~/.bashrc`
- verify:

```bash
"${MICROMAMBA_BIN}" --version
```

- print next steps:

```bash
source ~/.bashrc
make save-dotfiles
```

## Bash Hook Block

The script should append the hook only if the begin marker is not already
present.

Managed block:

```bash
# >>> banglab micromamba >>>
export MAMBA_ROOT_PREFIX="${HOME}/scratch/micromamba"
<micromamba shell hook output>
# <<< banglab micromamba <<<
```

## Script Mapping

```text
make install-micromamba  -> scripts/remote/install-micromamba.sh
```

Shared helpers:

```text
scripts/lib/log.sh
```

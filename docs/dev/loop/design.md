# Loop 6 Design: Micromamba Setup

Started: 2026-05-12

## Goal

Design a simple inside-instance workflow for installing micromamba on the
persistent EBS volume.

This loop should let a lab member:

- install micromamba once under `~/scratch/micromamba`
- reuse the same micromamba installation across disposable EC2 instances
- add the micromamba bash hook to `~/.bashrc`
- save the updated `~/.bashrc` with the Loop 5 dotfile workflow

This loop should follow the proven pattern from the older `MyAWS` script:

```text
MyAWS/motion-intelligence-ec2-setup/2c_one-time_install_micromamba.sh
```

## Workflow Shape

Inside an EC2 instance:

```bash
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-...
make restore-dotfiles
make install-micromamba
source ~/.bashrc
make save-dotfiles
```

Daily or new-instance reuse:

```bash
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-...
make restore-dotfiles
source ~/.bashrc
micromamba --version
```

## Prerequisites

This loop runs inside an EC2 instance.

The user should already have:

- launched or started an EC2 instance
- SSHed into the instance
- mounted persistent EBS at `~/scratch`
- restored dotfiles if they already have saved dotfiles
- `curl` and `tar` available
- network access to download micromamba

The command in this loop should not call AWS APIs.

## Scope

In scope:

- install micromamba under `~/scratch/micromamba`
- download the official Linux x86_64 micromamba tarball
- extract the `bin/micromamba` binary
- add an idempotent bash hook block to `~/.bashrc`
- verify `micromamba --version`
- skip install if the micromamba binary already exists
- remind the user to run `source ~/.bashrc`
- remind the user to run `make save-dotfiles`

Out of scope:

- creating micromamba environments
- installing CUDA, PyTorch, JAX, or research packages
- environment YAML management
- conda channel policy
- shell support beyond bash
- uninstalling micromamba
- updating micromamba
- automatic `make save-dotfiles`

## Install Layout

Persistent EBS install root:

```text
~/scratch/micromamba
```

Binary:

```text
~/scratch/micromamba/bin/micromamba
```

Environment/root prefix:

```text
MAMBA_ROOT_PREFIX=~/scratch/micromamba
```

## Bash Hook

The install command should append a managed block to `~/.bashrc` if it is not
already present.

Planned shape:

```bash
# >>> banglab micromamba >>>
export MAMBA_ROOT_PREFIX="$HOME/scratch/micromamba"
eval "$("$HOME/scratch/micromamba/bin/micromamba" shell hook --shell bash)"
# <<< banglab micromamba <<<
```

The exact hook contents can follow the output of:

```bash
micromamba shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX"
```

The script should avoid appending duplicate hook blocks.

## Planned User Commands

Inside-instance command:

```bash
make install-micromamba
```

### `make install-micromamba`

Purpose: install micromamba into persistent EBS and enable it in bash.

Expected behavior:

- require `~/scratch` to exist and be mounted
- set `MAMBA_ROOT_PREFIX=${HOME}/scratch/micromamba`
- set `MICROMAMBA_BIN=${HOME}/scratch/micromamba/bin/micromamba`
- if `MICROMAMBA_BIN` already exists and is executable:
  - print the existing path
  - print `micromamba --version`
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
- generate the bash hook
- append the bash hook block to `~/.bashrc` if missing
- verify `MICROMAMBA_BIN --version`
- print next steps:

```bash
source ~/.bashrc
make save-dotfiles
```

## User-Facing Docs To Draft

This loop should draft:

```text
docs/micromamba-setup.md
```

The doc should cover:

- this workflow runs inside the EC2 instance
- `~/scratch` must already be mounted
- micromamba is installed under `~/scratch/micromamba`
- the install is one-time per persistent EBS volume
- `~/.bashrc` gets a micromamba hook
- users should run `source ~/.bashrc`
- users should run `make save-dotfiles`
- environment creation is out of scope for this loop

## Planned Repo Structure

```text
banglab-aws-tools/
├── docs/
│   └── micromamba-setup.md
└── scripts/
    └── remote/
        └── install-micromamba.sh
```

The script can reuse `scripts/lib/log.sh`. It should not need AWS helpers.

## Open Questions

Resolved:

1. Use the official latest micromamba URL, matching the old script.
2. Generate the bash hook from `micromamba shell hook`, matching the old script.
3. Keep Loop 6 to a single `install-micromamba` command.

## Done Criteria

This loop is done when:

- `docs/dev/loop/design.md` is reviewed
- `docs/micromamba-setup.md` is drafted
- command/API docs are drafted
- Make target is implemented
- `install-micromamba` is implemented
- script is tested on an EC2 instance with mounted `~/scratch`
- `status_and_plan.md` is updated
- loop docs are archived according to `docs/dev/README.md`

## Loop Todo

1. Draft design doc: done
   - `docs/dev/loop/design.md`

2. Resolve open questions: done

3. Draft user-facing docs: done
   - `docs/micromamba-setup.md`

4. Draft command/API docs: done
   - `docs/dev/loop/api.md`

5. Add Make target: done
   - `install-micromamba`

6. Implement remote micromamba script: done
   - `scripts/remote/install-micromamba.sh`

7. Verify inside an EC2 instance with mounted `~/scratch`

8. Close and archive Loop 6

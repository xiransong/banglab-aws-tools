# Micromamba Setup

This page installs micromamba inside an EC2 instance.

Run this workflow inside the EC2 instance, not on your local laptop.

Before starting, `~/scratch` should already be mounted:

```bash
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

## What This Does

Micromamba is installed on persistent EBS:

```text
~/scratch/micromamba
```

The binary lives at:

```text
~/scratch/micromamba/bin/micromamba
```

The install command also adds a micromamba bash hook to:

```text
~/.bashrc
```

This means the micromamba installation can survive disposable EC2 instances, but
the shell setup still needs to be saved with the dotfile workflow.

## Step 1: Install Micromamba

Run inside the EC2 instance:

```bash
make install-micromamba
```

The command downloads the official Linux x86_64 micromamba build from:

```text
https://micro.mamba.pm/api/micromamba/linux-64/latest
```

If micromamba is already installed at `~/scratch/micromamba/bin/micromamba`, the
command skips the download and verifies the existing binary.

## Step 2: Reload Bash

After installation, run:

```bash
source ~/.bashrc
```

Then check:

```bash
micromamba --version
```

## Step 3: Save Dotfiles

Because the install command updates `~/.bashrc`, save dotfiles after installing:

```bash
make save-dotfiles
```

## Daily Pattern

On a fresh or restarted instance:

```bash
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
make restore-dotfiles
source ~/.bashrc
micromamba --version
```

## Scope

This page only installs micromamba.

It does not create environments or install research packages.

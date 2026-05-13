# GitHub And Dotfiles

This page sets up GitHub SSH access and simple dotfile persistence inside an
EC2 instance.

Run this workflow inside the EC2 instance, not on your local laptop.

Before starting, `~/scratch` should already be mounted:

```bash
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
```

## What Gets Saved

This workflow copies selected files between the disposable home directory and
persistent EBS.

Persistent copies live here:

```text
~/scratch/dotfiles/
├── bashrc
├── gitconfig
├── texlive-env
└── ssh/
    ├── id_ed25519
    └── id_ed25519.pub
```

Home directory files live here:

```text
~/.bashrc
~/.gitconfig
~/.texlive-env
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

The commands use plain copies, not symlinks.

## Step 1: Generate A GitHub SSH Key

Run inside the EC2 instance (remember to replace `your_email@example.com` with your own email address):

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

`ssh-keygen` will ask where to save the key. Use the default path, e.g.:

```text
/home/ubuntu/.ssh/id_ed25519
```

It may also ask whether to use a passphrase. Just press Enter to select the default values.

## Step 2: Add The Public Key To GitHub

Print the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Add it to your GitHub account as an SSH authentication key:

```text
https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account
```

Only add the `.pub` public key to GitHub. Do not share or upload the private
key.

## Step 3: Save Dotfiles To Persistent EBS

After GitHub SSH setup and any local config edits, run:

```bash
make save-dotfiles
```

This saves available files:

```text
~/.bashrc              -> ~/scratch/dotfiles/bashrc
~/.gitconfig           -> ~/scratch/dotfiles/gitconfig
~/.texlive-env         -> ~/scratch/dotfiles/texlive-env
~/.ssh/id_ed25519      -> ~/scratch/dotfiles/ssh/id_ed25519
~/.ssh/id_ed25519.pub  -> ~/scratch/dotfiles/ssh/id_ed25519.pub
```

Missing files are skipped with warnings.

Existing persistent copies are overwritten.

## Step 4: Restore On A New Instance

After launching a new EC2 instance and mounting `~/scratch`, run:

```bash
make restore-dotfiles
```

This restores available files:

```text
~/scratch/dotfiles/bashrc              -> ~/.bashrc
~/scratch/dotfiles/gitconfig           -> ~/.gitconfig
~/scratch/dotfiles/texlive-env         -> ~/.texlive-env
~/scratch/dotfiles/ssh/id_ed25519      -> ~/.ssh/id_ed25519
~/scratch/dotfiles/ssh/id_ed25519.pub  -> ~/.ssh/id_ed25519.pub
```

Existing home-directory files are overwritten.

Then run:

```bash
source ~/.bashrc
```

## Daily Pattern

On a fresh or restarted instance:

```bash
cd banglab-aws-tools
make mount-scratch VOLUME_ID=vol-0123456789abcdef0
make restore-dotfiles
source ~/.bashrc
```

When you change a file that should persist:

```bash
make save-dotfiles
```

## Security Note

The GitHub private key is stored on persistent EBS at:

```text
~/scratch/dotfiles/ssh/id_ed25519
```

This is intentional so your GitHub setup survives disposable EC2 instances.
Treat the persistent EBS volume as sensitive. Do not commit private keys to any
repository.

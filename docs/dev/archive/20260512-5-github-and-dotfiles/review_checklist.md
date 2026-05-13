# Loop 5 Review Checklist

## Docs

- [x] `docs/github-and-dotfiles.md` explains manual GitHub SSH-key generation.
- [x] `docs/github-and-dotfiles.md` explains adding the public key to GitHub.
- [x] `docs/github-and-dotfiles.md` explains `id_ed25519`.
- [x] `docs/github-and-dotfiles.md` explains `save-dotfiles`.
- [x] `docs/github-and-dotfiles.md` explains `restore-dotfiles`.
- [x] `docs/github-and-dotfiles.md` explains private-key persistence on EBS.
- [x] `docs/dev/loop/api.md` matches implemented Make targets and scripts.

## Local Checks

- [x] `make help` lists Loop 5 commands.
- [x] shell syntax checks pass.
- [x] `git diff --check` passes.
- [x] `save-dotfiles` fails before copying when `~/scratch` is not mounted.
- [x] `restore-dotfiles` fails before copying when `~/scratch` is not mounted.

## Manual Inside-Instance Checks

- [x] `make save-dotfiles`
- [x] `make restore-dotfiles`

## Decisions

- [x] No `generate-github-key` Make target.
- [x] GitHub key generation stays a manual `ssh-keygen` command.
- [x] SSH key filename is fixed as `id_ed25519`.
- [x] `~/.gitconfig` is included.
- [x] Save and restore overwrite existing destination files.

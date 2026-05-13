# Loop 5 Implementation Log

## 2026-05-12

Implemented GitHub and dotfile persistence.

Added Make targets:

- `make save-dotfiles`
- `make restore-dotfiles`

Added inside-instance scripts:

- `scripts/remote/save-dotfiles.sh`
- `scripts/remote/restore-dotfiles.sh`

Added user-facing docs:

- `docs/github-and-dotfiles.md`

Updated docs:

- `docs/README.md`
- `scripts/README.md`

Implementation notes:

- GitHub SSH-key generation is documented as a manual command:
  `ssh-keygen -t ed25519 -C "your_email@example.com"`.
- Users should accept the default SSH key path: `~/.ssh/id_ed25519`.
- Users manually add `~/.ssh/id_ed25519.pub` to GitHub.
- `save-dotfiles` copies selected files from the disposable home directory to
  `~/scratch/dotfiles`.
- `restore-dotfiles` copies selected files from `~/scratch/dotfiles` back to
  the disposable home directory.
- The workflow uses plain copies, not symlinks.
- Existing destination files are overwritten for simplicity.
- SSH key permissions are restored conservatively.

Files covered:

```text
~/.bashrc
~/.gitconfig
~/.texlive-env
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

Verification run by Codex:

- `bash -n` for Loop 5 scripts: passed
- `make help`: passed
- `git diff --check`: passed
- missing `~/scratch` guard for `save-dotfiles`: passed with temporary `HOME`
- missing `~/scratch` guard for `restore-dotfiles`: passed with temporary
  `HOME`

Manual verification run by Xiran:

- `save-dotfiles`: passed
- `restore-dotfiles`: passed

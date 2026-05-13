# Loop 6 Implementation Log

## 2026-05-12

Implemented micromamba setup.

Added Make target:

- `make install-micromamba`

Added inside-instance script:

- `scripts/remote/install-micromamba.sh`

Added user-facing docs:

- `docs/micromamba-setup.md`

Updated docs:

- `docs/README.md`
- `scripts/README.md`

Implementation notes:

- micromamba installs under `~/scratch/micromamba`.
- the binary path is `~/scratch/micromamba/bin/micromamba`.
- the script downloads the official latest Linux x86_64 micromamba tarball.
- the script skips download if the binary already exists and is executable.
- the script appends an idempotent `banglab micromamba` block to `~/.bashrc`.
- users should run `source ~/.bashrc` after installation.
- users should run `make save-dotfiles` after installation so the updated
  `~/.bashrc` is persisted.

Verification run by Codex:

- `bash -n scripts/remote/install-micromamba.sh`: passed
- `make help`: passed
- missing `~/scratch` guard: passed with temporary `HOME`
- `git diff --check`: passed

Manual verification run by Xiran:

- `make install-micromamba`: passed inside EC2 with mounted `~/scratch`

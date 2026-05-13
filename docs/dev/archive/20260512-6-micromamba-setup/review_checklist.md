# Loop 6 Review Checklist

## Docs

- [x] `docs/micromamba-setup.md` explains the inside-instance workflow.
- [x] `docs/micromamba-setup.md` explains that `~/scratch` must be mounted.
- [x] `docs/micromamba-setup.md` explains the install location.
- [x] `docs/micromamba-setup.md` explains `source ~/.bashrc`.
- [x] `docs/micromamba-setup.md` explains `make save-dotfiles`.
- [x] `docs/dev/loop/api.md` matches implemented Make targets and scripts.

## Local Checks

- [x] `make help` lists `install-micromamba`.
- [x] shell syntax checks pass.
- [x] `git diff --check` passes.
- [x] `install-micromamba` fails before download when `~/scratch` is not
      mounted.

## Manual Inside-Instance Checks

- [x] `make install-micromamba`

## Decisions

- [x] Use the official latest micromamba URL.
- [x] Generate the bash hook from `micromamba shell hook`.
- [x] Keep Loop 6 to one command: `install-micromamba`.

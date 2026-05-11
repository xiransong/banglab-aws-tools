# Development Docs

This folder is the development workspace for `banglab-aws-tools`.
Use it to draft plans, command/API designs, implementation notes, and loop
logs before anything becomes stable user-facing documentation.

## Development Cockpit

[`status_and_plan.md`](status_and_plan.md) is the cockpit for this repo.
If you return after a long break, read it first.

It should always answer:

- what the repo currently contains
- what the active development loop is, if any
- what state the active loop is in
- what decisions have already been made
- what the next concrete step is

Keep it short enough to scan, but complete enough to restart work safely.

## Loops

One implementation wave is called a **loop**.

At any time, there should be either:

- zero active loops, or
- one active loop in [`loop/`](loop/)

Do not run multiple active loops in parallel in this repo. If new work appears
while a loop is active, record it in `status_and_plan.md` as future work unless
it directly belongs to the current loop.

## Active Loop Folder

Use [`loop/`](loop/) for the current active loop.

Typical files:

```text
loop/
├── design.md
├── api.md
├── implementation_log.md
└── review_checklist.md
```

The exact files can vary by loop, but the loop should usually start with a
design draft before implementation begins.

## Closing a Loop

Before closing a loop:

- promote stable user-facing docs out of `docs/dev/loop`
- implement the agreed scripts or repo changes
- record important decisions and checks
- update `status_and_plan.md`
- move the loop folder into [`archive/`](archive/)

Archive folder names should use:

```text
archive/YYYYMMDD-N-short-name
```

Example:

```text
archive/20260511-1-aws-cli-setup
```

## Stability Rule

During an active loop, docs outside `docs/dev` should stay stable and
user-facing. Drafts, uncertain APIs, and implementation notes belong in
`docs/dev/loop` until they are ready to promote.

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/log.sh
source "${REPO_ROOT}/scripts/lib/log.sh"

SCRATCH="${HOME}/scratch"
DOTFILES="${SCRATCH}/dotfiles"
SSH_DOTFILES="${DOTFILES}/ssh"

require_scratch_mounted() {
  if [[ ! -d "${SCRATCH}" ]]; then
    die "Scratch directory not found: ${SCRATCH}. Run mount-scratch first."
  fi

  if ! mountpoint -q "${SCRATCH}"; then
    die "Scratch directory is not mounted: ${SCRATCH}. Run mount-scratch first."
  fi
}

restore_file() {
  local src="$1"
  local dst="$2"
  local mode="$3"
  local label="$4"

  if [[ -f "${src}" ]]; then
    info "Restoring ${label}"
    cp "${src}" "${dst}"
    chmod "${mode}" "${dst}"
    RESTORED_ITEMS+=("${dst}")
  else
    warn "${src} not found; skipping"
  fi
}

RESTORED_ITEMS=()

echo "========================================"
echo "Restoring dotfiles from persistent EBS"
echo "========================================"

require_scratch_mounted

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

restore_file "${DOTFILES}/bashrc" "${HOME}/.bashrc" 644 "~/.bashrc"
restore_file "${DOTFILES}/gitconfig" "${HOME}/.gitconfig" 644 "~/.gitconfig"
restore_file "${DOTFILES}/texlive-env" "${HOME}/.texlive-env" 644 "~/.texlive-env"
restore_file "${SSH_DOTFILES}/id_ed25519" "${HOME}/.ssh/id_ed25519" 600 "~/.ssh/id_ed25519"
restore_file "${SSH_DOTFILES}/id_ed25519.pub" "${HOME}/.ssh/id_ed25519.pub" 644 "~/.ssh/id_ed25519.pub"

echo
echo "========================================"
echo "DONE"
echo "Restored files:"
if [[ "${#RESTORED_ITEMS[@]}" -eq 0 ]]; then
  echo "  <none>"
else
  for item in "${RESTORED_ITEMS[@]}"; do
    printf '  - %s\n' "${item}"
  done
fi
echo
echo "Next steps:"
echo "  source ~/.bashrc"
echo "========================================"

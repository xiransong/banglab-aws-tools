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

save_file() {
  local src="$1"
  local dst="$2"
  local mode="$3"
  local label="$4"

  if [[ -f "${src}" ]]; then
    info "Saving ${label}"
    cp "${src}" "${dst}"
    chmod "${mode}" "${dst}"
    SAVED_ITEMS+=("${dst}")
  else
    warn "${src} not found; skipping"
  fi
}

SAVED_ITEMS=()

echo "========================================"
echo "Saving dotfiles to persistent EBS"
echo "========================================"

require_scratch_mounted

mkdir -p "${DOTFILES}" "${SSH_DOTFILES}"
chmod 700 "${DOTFILES}" "${SSH_DOTFILES}"

save_file "${HOME}/.bashrc" "${DOTFILES}/bashrc" 644 "~/.bashrc"
save_file "${HOME}/.gitconfig" "${DOTFILES}/gitconfig" 644 "~/.gitconfig"
save_file "${HOME}/.texlive-env" "${DOTFILES}/texlive-env" 644 "~/.texlive-env"
save_file "${HOME}/.ssh/id_ed25519" "${SSH_DOTFILES}/id_ed25519" 600 "~/.ssh/id_ed25519"
save_file "${HOME}/.ssh/id_ed25519.pub" "${SSH_DOTFILES}/id_ed25519.pub" 644 "~/.ssh/id_ed25519.pub"

echo
echo "========================================"
echo "DONE"
echo "Saved files:"
if [[ "${#SAVED_ITEMS[@]}" -eq 0 ]]; then
  echo "  <none>"
else
  for item in "${SAVED_ITEMS[@]}"; do
    printf '  - %s\n' "${item}"
  done
fi
echo
echo "NOTE:"
echo "  The GitHub private key is stored on persistent EBS if present."
echo "  Do not commit private keys to any repository."
echo "========================================"

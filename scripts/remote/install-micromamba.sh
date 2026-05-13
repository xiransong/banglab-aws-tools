#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/log.sh
source "${REPO_ROOT}/scripts/lib/log.sh"

SCRATCH="${HOME}/scratch"
MAMBA_ROOT_PREFIX="${SCRATCH}/micromamba"
BIN_DIR="${MAMBA_ROOT_PREFIX}/bin"
MICROMAMBA_BIN="${BIN_DIR}/micromamba"
MICROMAMBA_URL="https://micro.mamba.pm/api/micromamba/linux-64/latest"
BASHRC="${HOME}/.bashrc"
BEGIN_MARKER="# >>> banglab micromamba >>>"
END_MARKER="# <<< banglab micromamba <<<"

require_command() {
  local cmd="$1"

  if ! command -v "${cmd}" >/dev/null 2>&1; then
    die "Required command not found: ${cmd}"
  fi
}

require_scratch_mounted() {
  if [[ ! -d "${SCRATCH}" ]]; then
    die "Scratch directory not found: ${SCRATCH}. Run mount-scratch first."
  fi

  if ! mountpoint -q "${SCRATCH}"; then
    die "Scratch directory is not mounted: ${SCRATCH}. Run mount-scratch first."
  fi
}

ensure_bash_hook() {
  local tmp_dir="$1"
  local hook_file="${tmp_dir}/micromamba_hook.sh"

  if [[ -f "${BASHRC}" ]] && grep -qF "${BEGIN_MARKER}" "${BASHRC}"; then
    ok "Micromamba bash hook already present in ${BASHRC}"
    return
  fi

  info "Generating micromamba bash hook..."
  "${MICROMAMBA_BIN}" shell hook \
    --shell bash \
    --root-prefix "${MAMBA_ROOT_PREFIX}" \
    > "${hook_file}"

  info "Appending micromamba bash hook to ${BASHRC}"
  {
    echo
    echo "${BEGIN_MARKER}"
    printf 'export MAMBA_ROOT_PREFIX="%s"\n' "${MAMBA_ROOT_PREFIX}"
    cat "${hook_file}"
    echo "${END_MARKER}"
  } >> "${BASHRC}"
}

echo "============================================================"
echo "[INFO] Installing micromamba under persistent EBS"
echo "============================================================"

require_scratch_mounted
require_command curl
require_command tar

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

if [[ -x "${MICROMAMBA_BIN}" ]]; then
  ok "micromamba already installed: ${MICROMAMBA_BIN}"
  "${MICROMAMBA_BIN}" --version
  ensure_bash_hook "${tmp_dir}"
else
  info "Creating micromamba directories..."
  mkdir -p "${BIN_DIR}"

  info "Downloading micromamba..."
  curl -L "${MICROMAMBA_URL}" -o "${tmp_dir}/micromamba.tar.bz2"

  info "Extracting micromamba..."
  tar -xjf "${tmp_dir}/micromamba.tar.bz2" -C "${tmp_dir}"

  if [[ ! -f "${tmp_dir}/bin/micromamba" ]]; then
    die "micromamba binary not found after extraction."
  fi

  mv "${tmp_dir}/bin/micromamba" "${MICROMAMBA_BIN}"
  chmod +x "${MICROMAMBA_BIN}"

  ensure_bash_hook "${tmp_dir}"
fi

info "Verifying micromamba installation..."
export MAMBA_ROOT_PREFIX
"${MICROMAMBA_BIN}" --version

echo "============================================================"
ok "micromamba is ready"
printf '[INFO] Location: %s\n' "${MICROMAMBA_BIN}"
printf '[INFO] Root prefix: %s\n' "${MAMBA_ROOT_PREFIX}"
echo "[INFO] Next:"
echo "  source ~/.bashrc"
echo "  make save-dotfiles"
echo "============================================================"

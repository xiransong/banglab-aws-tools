#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

load_config
validate_ssh_config

if [[ -e "${SSH_KEY_PATH}" || -e "${SSH_KEY_PATH}.pub" ]]; then
  die "SSH key already exists. Refusing to overwrite: ${SSH_KEY_PATH}"
fi

mkdir -p "$(dirname "${SSH_KEY_PATH}")"
chmod 700 "$(dirname "${SSH_KEY_PATH}")"

ssh-keygen \
  -t ed25519 \
  -f "${SSH_KEY_PATH}" \
  -C "${OWNER}@banglab-aws-tools" \
  -N ""

chmod 600 "${SSH_KEY_PATH}"
chmod 644 "${SSH_KEY_PATH}.pub"

ok "Created SSH key pair:"
echo "  ${SSH_KEY_PATH}"
echo "  ${SSH_KEY_PATH}.pub"
info "Next: make import-key"

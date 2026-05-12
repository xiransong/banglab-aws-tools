#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

EXAMPLE="${REPO_ROOT}/config.example.env"
TARGET="${CONFIG_FILE:-${REPO_ROOT}/config.env}"

if [[ ! -f "${EXAMPLE}" ]]; then
  die "Missing config example: ${EXAMPLE}"
fi

if [[ -e "${TARGET}" ]]; then
  die "config.env already exists. Refusing to overwrite: ${TARGET}"
fi

cp "${EXAMPLE}" "${TARGET}"

ok "Created config.env"

load_config
print_config_summary

echo
echo "========================================"
echo "ACTION REQUIRED"
echo "========================================"
echo "Before continuing, edit the user-specific fields in:"
echo
echo "  ${TARGET}"
echo
echo "The example values are for the test user. Replace them with your own:"
echo
echo "  OWNER"
echo "  AWS_PROFILE"
echo "  AWS_ACCOUNT_LABEL"
echo "  AWS_ACCOUNT_ID"
echo "  AWS_SSO_SESSION"
echo
echo "For a new user, OWNER and AWS_PROFILE are usually the same username."
echo "AWS_SSO_SESSION is usually banglab-\${OWNER}."
echo "You can copy AWS_ACCOUNT_ID from the AWS Access Portal."
echo "========================================"
echo
info "Then run: make doctor"

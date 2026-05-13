#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"
# shellcheck source=../lib/checks.sh
source "${REPO_ROOT}/scripts/lib/checks.sh"

echo "========================================"
echo "banglab-aws-tools doctor"
echo "========================================"

load_config
print_config_summary

echo
validate_local_config
ok "config.env loaded and required variables are set"

failures=0

check_aws_cli_v2 || failures=1
check_command make || failures=1
check_command git || failures=1
check_command ssh || failures=1
check_command curl || failures=1
check_command jq || failures=1

echo
if [[ "${failures}" -eq 0 ]]; then
  ok "Local machine setup checks passed."
  info "Next: make configure-aws-sso"
else
  die "One or more local machine setup checks failed."
fi

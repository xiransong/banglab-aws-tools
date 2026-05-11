#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

load_config
require_config_vars AWS_PROFILE

info "Logging in with AWS profile: ${AWS_PROFILE}"
aws sso login --profile "${AWS_PROFILE}"

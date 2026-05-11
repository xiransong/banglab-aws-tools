#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

load_config
require_config_vars AWS_PROFILE

info "Checking AWS identity with profile: ${AWS_PROFILE}"
aws sts get-caller-identity --profile "${AWS_PROFILE}"

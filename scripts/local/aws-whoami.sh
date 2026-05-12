#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

load_config
require_config_vars AWS_PROFILE OWNER AWS_ACCOUNT_ID AWS_SSO_ROLE_NAME

info "Checking AWS identity with profile: ${AWS_PROFILE}"
identity_json="$(aws sts get-caller-identity --profile "${AWS_PROFILE}")"
printf '%s\n' "${identity_json}"

if ! command -v jq >/dev/null 2>&1; then
  warn "jq not found; skipping identity consistency checks."
  exit 0
fi

account="$(printf '%s\n' "${identity_json}" | jq -r '.Account // empty')"
arn="$(printf '%s\n' "${identity_json}" | jq -r '.Arn // empty')"
session_name="${arn##*/}"

if [[ "${account}" != "${AWS_ACCOUNT_ID}" ]]; then
  die "AWS identity account ${account} does not match AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}."
fi

if [[ "${arn}" != *":assumed-role/"*"${AWS_SSO_ROLE_NAME}"*"/"* ]]; then
  die "AWS identity does not appear to be using role ${AWS_SSO_ROLE_NAME}."
fi

if [[ "${session_name}" != "${OWNER}" ]]; then
  die "AWS SSO login session is ${session_name}, but OWNER=${OWNER}. Run 'aws sso logout', make sure AWS_SSO_SESSION is unique for this user, then run 'make configure-aws-sso' and 'make aws-login'."
fi

ok "AWS identity matches OWNER=${OWNER}, account=${AWS_ACCOUNT_ID}, role=${AWS_SSO_ROLE_NAME}."

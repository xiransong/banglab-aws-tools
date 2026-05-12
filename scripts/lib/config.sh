#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${LIB_DIR}/../.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${REPO_ROOT}/config.env}"

# shellcheck source=log.sh
source "${LIB_DIR}/log.sh"

load_config() {
  if [[ ! -f "${CONFIG_FILE}" ]]; then
    die "config.env not found. Run: make init-config"
  fi

  set -a
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
  set +a

  apply_config_defaults
}

apply_config_defaults() {
  SSH_KEY_PATH="${SSH_KEY_PATH:-${HOME}/.ssh/${OWNER:-}}"
  KEY_NAME="${KEY_NAME:-${OWNER:-}-key}"
  SECURITY_GROUP_NAME="${SECURITY_GROUP_NAME:-${OWNER:-}-ssh}"
  SSH_PORT="${SSH_PORT:-22}"
}

require_config_vars() {
  local missing=0
  local name

  for name in "$@"; do
    if [[ -z "${!name:-}" ]]; then
      fail "Missing required config variable: ${name}"
      missing=1
    fi
  done

  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi
}

required_loop1_config_vars() {
  printf '%s\n' \
    OWNER \
    AWS_PROFILE \
    AWS_REGION \
    AWS_ACCOUNT_LABEL \
    AWS_ACCOUNT_ID \
    AWS_SSO_START_URL \
    AWS_SSO_REGION \
    AWS_SSO_ROLE_NAME \
    AWS_SSO_SESSION
}

validate_loop1_config() {
  require_config_vars \
    OWNER \
    AWS_PROFILE \
    AWS_REGION \
    AWS_ACCOUNT_LABEL \
    AWS_ACCOUNT_ID \
    AWS_SSO_START_URL \
    AWS_SSO_REGION \
    AWS_SSO_ROLE_NAME \
    AWS_SSO_SESSION

  if [[ ! "${AWS_ACCOUNT_ID}" =~ ^[0-9]{12}$ ]]; then
    die "AWS_ACCOUNT_ID must be a 12-digit AWS account ID."
  fi

  if [[ ! "${AWS_PROFILE}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    die "AWS_PROFILE should contain only letters, numbers, dots, underscores, and hyphens."
  fi

  if [[ ! "${AWS_SSO_SESSION}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    die "AWS_SSO_SESSION should contain only letters, numbers, dots, underscores, and hyphens."
  fi
}

validate_loop2_config() {
  validate_loop1_config
  require_config_vars \
    SSH_KEY_PATH \
    KEY_NAME \
    SECURITY_GROUP_NAME \
    SSH_PORT

  if [[ ! "${SSH_PORT}" =~ ^[0-9]+$ ]]; then
    die "SSH_PORT must be a number."
  fi
}

print_config_summary() {
  echo
  echo "Config summary (${CONFIG_FILE}):"
  echo
  echo "User-specific fields:"
  printf '  OWNER=%s\n' "${OWNER:-<unset>}"
  printf '  AWS_PROFILE=%s\n' "${AWS_PROFILE:-<unset>}"
  printf '  AWS_ACCOUNT_LABEL=%s\n' "${AWS_ACCOUNT_LABEL:-<unset>}"
  printf '  AWS_ACCOUNT_ID=%s\n' "${AWS_ACCOUNT_ID:-<unset>}"
  echo
  echo "BangLab defaults:"
  printf '  AWS_REGION=%s\n' "${AWS_REGION:-<unset>}"
  printf '  AWS_SSO_START_URL=%s\n' "${AWS_SSO_START_URL:-<unset>}"
  printf '  AWS_SSO_REGION=%s\n' "${AWS_SSO_REGION:-<unset>}"
  printf '  AWS_SSO_ROLE_NAME=%s\n' "${AWS_SSO_ROLE_NAME:-<unset>}"
  printf '  AWS_SSO_SESSION=%s\n' "${AWS_SSO_SESSION:-<unset>}"
  printf '  DEFAULT_AVAILABILITY_ZONE=%s\n' "${DEFAULT_AVAILABILITY_ZONE:-<unset>}"
  echo
  echo "SSH access defaults:"
  printf '  SSH_KEY_PATH=%s\n' "${SSH_KEY_PATH:-<unset>}"
  printf '  KEY_NAME=%s\n' "${KEY_NAME:-<unset>}"
  printf '  SECURITY_GROUP_NAME=%s\n' "${SECURITY_GROUP_NAME:-<unset>}"
  printf '  SSH_PORT=%s\n' "${SSH_PORT:-<unset>}"
}

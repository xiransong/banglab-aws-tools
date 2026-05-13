#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

load_config
validate_local_config

if [[ -n "${AWS_CONFIG_FILE:-}" ]]; then
  AWS_DIR="$(dirname "${AWS_CONFIG_FILE}")"
  custom_config_file=1
else
  AWS_DIR="${AWS_CONFIG_DIR:-${HOME}/.aws}"
  AWS_CONFIG_FILE="${AWS_DIR}/config"
  custom_config_file=0
fi

mkdir -p "${AWS_DIR}"
touch "${AWS_CONFIG_FILE}"
if [[ "${custom_config_file}" -eq 0 ]]; then
  chmod 700 "${AWS_DIR}" 2>/dev/null || warn "Could not chmod ${AWS_DIR}; continuing."
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup="${AWS_CONFIG_FILE}.bak.${timestamp}"
cp "${AWS_CONFIG_FILE}" "${backup}"

tmp_file="$(mktemp)"
trap 'rm -f "${tmp_file}"' EXIT

profile_section="[profile ${AWS_PROFILE}]"
sso_section="[sso-session ${AWS_SSO_SESSION}]"

awk \
  -v profile_section="${profile_section}" \
  -v sso_section="${sso_section}" \
  '
    /^\[/ {
      skip = ($0 == profile_section || $0 == sso_section)
    }
    !skip {
      print
    }
  ' "${AWS_CONFIG_FILE}" > "${tmp_file}"

cat >> "${tmp_file}" <<EOF

[profile ${AWS_PROFILE}]
sso_session = ${AWS_SSO_SESSION}
sso_account_id = ${AWS_ACCOUNT_ID}
sso_role_name = ${AWS_SSO_ROLE_NAME}
region = ${AWS_REGION}
output = json

[sso-session ${AWS_SSO_SESSION}]
sso_start_url = ${AWS_SSO_START_URL}
sso_region = ${AWS_SSO_REGION}
sso_registration_scopes = sso:account:access
EOF

mv "${tmp_file}" "${AWS_CONFIG_FILE}"
chmod 600 "${AWS_CONFIG_FILE}"
trap - EXIT

ok "Updated AWS CLI config: ${AWS_CONFIG_FILE}"
info "Backup saved at: ${backup}"
info "Configured profile: ${AWS_PROFILE}"
info "Next: make aws-login"

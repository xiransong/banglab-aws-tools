#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

echo "========================================"
echo "banglab-aws-tools SSH status"
echo "========================================"

load_config
validate_loop2_config

echo
echo "Local SSH key:"
if [[ -f "${SSH_KEY_PATH}" ]]; then
  ok "Private key exists: ${SSH_KEY_PATH}"
else
  warn "Private key missing: ${SSH_KEY_PATH}"
fi

if [[ -f "${SSH_KEY_PATH}.pub" ]]; then
  ok "Public key exists: ${SSH_KEY_PATH}.pub"
else
  warn "Public key missing: ${SSH_KEY_PATH}.pub"
fi

echo
echo "AWS key pair:"
if key_pair_exists; then
  owner="$(get_key_pair_owner)"
  ok "AWS key pair exists: ${KEY_NAME}"
  if [[ "${owner}" == "${OWNER}" ]]; then
    ok "Key pair Owner tag matches: ${OWNER}"
  else
    warn "Key pair Owner tag is ${owner:-<missing>}, expected ${OWNER}"
  fi
else
  warn "AWS key pair missing: ${KEY_NAME}"
fi

echo
echo "Default VPC:"
if vpc_id="$(get_default_vpc_id)"; then
  ok "Default VPC: ${vpc_id}"
else
  warn "No default VPC found."
  exit 0
fi

echo
echo "Security group:"
if security_group_exists "${vpc_id}"; then
  group_id="$(get_security_group_id "${vpc_id}")"
  owner="$(get_security_group_owner "${vpc_id}")"
  ok "Security group exists: ${SECURITY_GROUP_NAME} (${group_id})"
  if [[ "${owner}" == "${OWNER}" ]]; then
    ok "Security group Owner tag matches: ${OWNER}"
  else
    warn "Security group Owner tag is ${owner:-<missing>}, expected ${OWNER}"
  fi

  echo
  echo "SSH inbound rules:"
  rules="$(
    get_security_group_json "${vpc_id}" | jq -r --argjson port "${SSH_PORT}" '
      .SecurityGroups[0].IpPermissions[]?
      | select(.IpProtocol == "tcp" and .FromPort == $port and .ToPort == $port)
      | .IpRanges[]?
      | "  - " + .CidrIp + "  " + (.Description // "<no description>")
    '
  )"

  if [[ -n "${rules}" ]]; then
    printf '%s\n' "${rules}"
  else
    warn "No SSH inbound rules found on ${SECURITY_GROUP_NAME}."
  fi
else
  warn "Security group missing: ${SECURITY_GROUP_NAME}"
fi

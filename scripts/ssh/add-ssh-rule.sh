#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ssh_config
require_config_vars SSH_RULE_NAME

if [[ ! "${SSH_RULE_NAME}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  die "SSH_RULE_NAME should contain only letters, numbers, dots, underscores, and hyphens."
fi

if ! vpc_id="$(get_default_vpc_id)"; then
  die "No default VPC found in ${AWS_REGION}. Custom VPC support is not currently supported by this toolbox."
fi

if ! security_group_exists "${vpc_id}"; then
  die "Security group not found: ${SECURITY_GROUP_NAME}. Run: make create-security-group"
fi

ensure_security_group_owned_by_user "${vpc_id}"
group_id="$(get_security_group_id "${vpc_id}")"

current_ip="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"
if [[ ! "${current_ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  die "Could not determine a valid public IPv4 address. Got: ${current_ip}"
fi

cidr="${current_ip}/32"
description="${OWNER}-${SSH_RULE_NAME}"

existing="$(
  get_security_group_json "${vpc_id}" | jq -r \
    --arg cidr "${cidr}" \
    --argjson port "${SSH_PORT}" '
      .SecurityGroups[0].IpPermissions[]?
      | select(.IpProtocol == "tcp" and .FromPort == $port and .ToPort == $port)
      | .IpRanges[]?
      | select(.CidrIp == $cidr)
      | .CidrIp
    ' | head -n 1
)"

if [[ -n "${existing}" ]]; then
  ok "SSH rule already exists for ${cidr} on ${SECURITY_GROUP_NAME}"
  exit 0
fi

aws_ec2 authorize-security-group-ingress \
  --group-id "${group_id}" \
  --ip-permissions "IpProtocol=tcp,FromPort=${SSH_PORT},ToPort=${SSH_PORT},IpRanges=[{CidrIp=${cidr},Description=${description}}]" \
  >/dev/null

ok "Added SSH rule to ${SECURITY_GROUP_NAME}: ${cidr}"
info "Description: ${description}"

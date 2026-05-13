#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ssh_config

if ! vpc_id="$(get_default_vpc_id)"; then
  die "No default VPC found in ${AWS_REGION}. Custom VPC support is not currently supported by this toolbox."
fi

if security_group_exists "${vpc_id}"; then
  ensure_security_group_owned_by_user "${vpc_id}"
  group_id="$(get_security_group_id "${vpc_id}")"
  ok "Security group already exists: ${SECURITY_GROUP_NAME} (${group_id})"
  exit 0
fi

group_id="$(
  aws_ec2 create-security-group \
    --vpc-id "${vpc_id}" \
    --group-name "${SECURITY_GROUP_NAME}" \
    --description "SSH access for ${OWNER}" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${SECURITY_GROUP_NAME}}]" \
    --query 'GroupId' \
    --output text
)"

ok "Created security group: ${SECURITY_GROUP_NAME} (${group_id})"
info "Tags: Owner=${OWNER}, Name=${SECURITY_GROUP_NAME}"
info "Next: make add-ssh-rule SSH_RULE_NAME=home"

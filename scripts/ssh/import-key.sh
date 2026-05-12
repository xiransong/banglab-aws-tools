#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_loop2_config

if [[ ! -f "${SSH_KEY_PATH}.pub" ]]; then
  die "Public key not found: ${SSH_KEY_PATH}.pub. Run: make create-key"
fi

if key_pair_exists; then
  ensure_key_pair_owned_by_user
  ok "AWS key pair already exists: ${KEY_NAME}"
  ok "Key pair Owner tag matches: ${OWNER}"
  exit 0
fi

tmp_err="$(mktemp)"
trap 'rm -f "${tmp_err}"' EXIT

if aws_ec2 import-key-pair \
  --key-name "${KEY_NAME}" \
  --public-key-material "fileb://${SSH_KEY_PATH}.pub" \
  --tag-specifications "ResourceType=key-pair,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${KEY_NAME}}]" \
  >/dev/null 2>"${tmp_err}"; then
  ok "Imported AWS key pair: ${KEY_NAME}"
  info "Tags: Owner=${OWNER}, Name=${KEY_NAME}"
  exit 0
fi

cat "${tmp_err}" >&2
echo >&2
fail "Failed to import owner-tagged key pair: ${KEY_NAME}"
warn "EC2 tag-on-create requires ec2:CreateTags permission for ImportKeyPair."
warn "If this is an authorization error, confirm your AWS CLI profile is using"
warn "the updated EC2-GPU-Operator permission set."
exit 1

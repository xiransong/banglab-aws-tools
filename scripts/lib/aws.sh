#!/usr/bin/env bash

# shellcheck source=config.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.sh"

aws_ec2() {
  aws ec2 \
    --region "${AWS_REGION}" \
    --profile "${AWS_PROFILE}" \
    "$@"
}

get_default_vpc_id() {
  local vpc_id

  vpc_id="$(
    aws_ec2 describe-vpcs \
      --filters Name=isDefault,Values=true \
      --query 'Vpcs[0].VpcId' \
      --output text
  )"

  if [[ -z "${vpc_id}" || "${vpc_id}" == "None" ]]; then
    return 1
  fi

  printf '%s\n' "${vpc_id}"
}

key_pair_exists() {
  aws_ec2 describe-key-pairs \
    --key-names "${KEY_NAME}" \
    --output json >/dev/null 2>&1
}

get_key_pair_json() {
  aws_ec2 describe-key-pairs \
    --key-names "${KEY_NAME}" \
    --output json
}

get_key_pair_owner() {
  get_key_pair_json | jq -r '.KeyPairs[0].Tags[]? | select(.Key == "Owner") | .Value' | head -n 1
}

ensure_key_pair_owned_by_user() {
  local owner

  owner="$(get_key_pair_owner)"

  if [[ "${owner}" != "${OWNER}" ]]; then
    die "Key pair ${KEY_NAME} exists but is not tagged Owner=${OWNER}."
  fi
}

get_security_group_json() {
  local vpc_id="$1"

  aws_ec2 describe-security-groups \
    --filters \
      "Name=vpc-id,Values=${vpc_id}" \
      "Name=group-name,Values=${SECURITY_GROUP_NAME}" \
    --output json
}

get_security_group_id() {
  local vpc_id="$1"

  get_security_group_json "${vpc_id}" | jq -r '.SecurityGroups[0].GroupId // empty'
}

get_security_group_owner() {
  local vpc_id="$1"

  get_security_group_json "${vpc_id}" | jq -r '.SecurityGroups[0].Tags[]? | select(.Key == "Owner") | .Value' | head -n 1
}

security_group_exists() {
  local vpc_id="$1"
  local group_id

  group_id="$(get_security_group_id "${vpc_id}")"
  [[ -n "${group_id}" ]]
}

ensure_security_group_owned_by_user() {
  local vpc_id="$1"
  local owner

  owner="$(get_security_group_owner "${vpc_id}")"

  if [[ "${owner}" != "${OWNER}" ]]; then
    die "Security group ${SECURITY_GROUP_NAME} exists but is not tagged Owner=${OWNER}."
  fi
}

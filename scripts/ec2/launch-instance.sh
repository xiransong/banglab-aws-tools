#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ec2_config
validate_instance_name
load_instance_config

if ! vpc_id="$(get_default_vpc_id)"; then
  die "No default VPC found in ${AWS_REGION}. Custom VPC support is not currently supported by this toolbox."
fi

if ! subnet_id="$(get_subnet_id_for_default_az "${vpc_id}")"; then
  die "No subnet found in ${DEFAULT_AVAILABILITY_ZONE} for default VPC ${vpc_id}."
fi

if ! key_pair_exists; then
  die "AWS key pair missing: ${KEY_NAME}. Run: make import-key"
fi
ensure_key_pair_owned_by_user

if ! security_group_exists "${vpc_id}"; then
  die "Security group missing: ${SECURITY_GROUP_NAME}. Run: make create-security-group"
fi
ensure_security_group_owned_by_user "${vpc_id}"
security_group_id="$(get_security_group_id "${vpc_id}")"

if ! root_device_name="$(get_ami_root_device_name)"; then
  die "Could not determine root device name for AMI_ID=${AMI_ID}."
fi

if [[ "$(get_named_active_instance_count)" != "0" ]]; then
  die "An active instance already exists with Owner=${OWNER}, Name=${INSTANCE_NAME}."
fi

block_device_mappings="$(
  printf '[{"DeviceName":"%s","Ebs":{"VolumeSize":%s,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
    "${root_device_name}" \
    "${ROOT_VOLUME_SIZE_GB}"
)"

info "Launching EC2 instance:"
printf '  Name=%s\n' "${INSTANCE_NAME}"
printf '  AMI_ID=%s\n' "${AMI_ID}"
printf '  INSTANCE_TYPE=%s\n' "${INSTANCE_TYPE}"
printf '  ROOT_VOLUME_SIZE_GB=%s\n' "${ROOT_VOLUME_SIZE_GB}"
printf '  AvailabilityZone=%s\n' "${DEFAULT_AVAILABILITY_ZONE}"

instance_id="$(
  aws_ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${security_group_id}" \
    --subnet-id "${subnet_id}" \
    --block-device-mappings "${block_device_mappings}" \
    --tag-specifications \
      "ResourceType=instance,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${INSTANCE_NAME}}]" \
      "ResourceType=volume,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${INSTANCE_NAME}-root}]" \
    --count 1 \
    --query 'Instances[0].InstanceId' \
    --output text
)"

ok "Launch accepted: ${instance_id}"
info "Waiting for instance to reach running..."

attempts=0
max_attempts=60

while true; do
  if state="$(try_get_instance_state "${instance_id}")"; then
    :
  else
    status=$?
    if [[ "${status}" == "2" ]]; then
      state="not-yet-visible"
    else
      exit "${status}"
    fi
  fi

  if [[ "${state}" == "running" ]]; then
    break
  fi
  if [[ "${state}" == "shutting-down" || "${state}" == "terminated" || "${state}" == "stopped" ]]; then
    die "Instance ${instance_id} reached unexpected state while launching: ${state}"
  fi
  attempts=$((attempts + 1))
  if [[ "${attempts}" -ge "${max_attempts}" ]]; then
    die "Timed out waiting for instance ${instance_id} to reach running. Current state: ${state}"
  fi
  info "${state}..."
  sleep 10
done

public_ip="$(get_instance_public_ip "${instance_id}")"

ok "Instance is running: ${instance_id}"
if [[ -n "${public_ip}" ]]; then
  info "Public IP: ${public_ip}"
else
  warn "No public IP found yet. Try: make instance-status INSTANCE_NAME=${INSTANCE_NAME}"
fi

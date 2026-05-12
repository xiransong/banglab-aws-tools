#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_loop4_config
validate_volume_id
validate_instance_name

ensure_volume_owned_by_user

volume_state="$(get_volume_field State)"
volume_az="$(get_volume_field AvailabilityZone)"

if [[ "${volume_state}" != "available" ]]; then
  die "Volume ${VOLUME_ID} is ${volume_state}, not available."
fi

instance_id="$(resolve_named_active_instance_id)"
instance_state="$(get_instance_state "${instance_id}")"

if [[ "${instance_state}" != "running" ]]; then
  die "Instance ${INSTANCE_NAME} is ${instance_state}, not running."
fi

instance_az="$(
  aws_ec2 describe-instances \
    --instance-ids "${instance_id}" \
    --query 'Reservations[0].Instances[0].Placement.AvailabilityZone' \
    --output text
)"

if [[ "${volume_az}" != "${instance_az}" ]]; then
  die "Volume ${VOLUME_ID} is in ${volume_az}, but instance ${INSTANCE_NAME} is in ${instance_az}."
fi

info "Attaching volume:"
printf '  VolumeId=%s\n' "${VOLUME_ID}"
printf '  Instance=%s (%s)\n' "${INSTANCE_NAME}" "${instance_id}"
printf '  Device=/dev/sdf\n'

aws_ec2 attach-volume \
  --volume-id "${VOLUME_ID}" \
  --instance-id "${instance_id}" \
  --device /dev/sdf >/dev/null

info "Waiting for attachment to reach attached..."

attempts=0
max_attempts=60

while true; do
  attachment_state="$(get_volume_attachment_state)"
  if [[ "${attachment_state}" == "attached" ]]; then
    break
  fi
  attempts=$((attempts + 1))
  if [[ "${attempts}" -ge "${max_attempts}" ]]; then
    die "Timed out waiting for volume ${VOLUME_ID} to attach. Current state: ${attachment_state:-<missing>}"
  fi
  info "${attachment_state:-attaching}..."
  sleep 5
done

ok "Volume attached: ${VOLUME_ID}"
info "Next: ssh ec2"
info "Then, inside the instance:"
info "  make setup-scratch VOLUME_ID=${VOLUME_ID} CONFIRM_SETUP_SCRATCH=YES"
info "or, if already initialized:"
info "  make mount-scratch VOLUME_ID=${VOLUME_ID}"

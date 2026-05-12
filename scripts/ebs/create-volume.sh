#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_loop4_config
validate_volume_name
validate_volume_size_gb

if [[ "$(get_named_volume_count)" != "0" ]]; then
  die "A volume already exists with Owner=${OWNER}, Name=${VOLUME_NAME}."
fi

info "Creating persistent EBS volume:"
printf '  Name=%s\n' "${VOLUME_NAME}"
printf '  Size=%s GiB\n' "${VOLUME_SIZE_GB}"
printf '  Type=gp3\n'
printf '  AvailabilityZone=%s\n' "${DEFAULT_AVAILABILITY_ZONE}"

volume_id="$(
  aws_ec2 create-volume \
    --availability-zone "${DEFAULT_AVAILABILITY_ZONE}" \
    --size "${VOLUME_SIZE_GB}" \
    --volume-type gp3 \
    --tag-specifications "ResourceType=volume,Tags=[{Key=Owner,Value=${OWNER}},{Key=Name,Value=${VOLUME_NAME}}]" \
    --query 'VolumeId' \
    --output text
)"

ok "Created volume: ${volume_id}"
info "Waiting for volume to become available..."
aws_ec2 wait volume-available --volume-ids "${volume_id}"

ok "Volume is available: ${volume_id}"
info "This VolumeId is needed for daily workflow: ${volume_id}. You can retrieve it with: make volumes"
info "Next: make attach-volume VOLUME_ID=${volume_id} INSTANCE_NAME=dev"

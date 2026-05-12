#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_loop4_config

info "Listing EBS volumes with Owner=${OWNER}"

volumes="$(get_owned_volumes_json | jq '[.Volumes[]?]')"

if [[ "${volumes}" == "[]" ]]; then
  warn "No EBS volumes found for Owner=${OWNER}."
  exit 0
fi

printf '%s\n' "${volumes}" | jq -r '
  sort_by(.CreateTime)
  | reverse
  | to_entries[]
  | .value as $v
  | ($v.Attachments[0] // {}) as $a
  | "volume " + ((.key + 1) | tostring) + ":",
    "  name: " + (($v.Tags[]? | select(.Key == "Name") | .Value) // "-"),
    "  id: " + $v.VolumeId,
    "  state: " + $v.State,
    "  size_gb: " + ($v.Size | tostring),
    "  type: " + $v.VolumeType,
    "  availability_zone: " + $v.AvailabilityZone,
    "  attached_instance: " + ($a.InstanceId // "-"),
    "  device: " + ($a.Device // "-"),
    ""
'

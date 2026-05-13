#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ec2_config

info "Listing EC2 instances with Owner=${OWNER}"

instances="$(get_owned_instances_json | jq '[.Reservations[].Instances[]?]')"

if [[ "${instances}" == "[]" ]]; then
  warn "No EC2 instances found for Owner=${OWNER}."
  exit 0
fi

printf '%s\n' "${instances}" | jq -r '
  sort_by(.LaunchTime)
  | reverse
  | to_entries[]
  | .value as $i
  | "instance " + ((.key + 1) | tostring) + ":",
    "  name: " + (($i.Tags[]? | select(.Key == "Name") | .Value) // "-"),
    "  id: " + $i.InstanceId,
    "  state: " + $i.State.Name,
    "  type: " + $i.InstanceType,
    "  public_ip: " + ($i.PublicIpAddress // "-"),
    "  private_ip: " + ($i.PrivateIpAddress // "-"),
    "  launch_time: " + $i.LaunchTime,
    ""
'

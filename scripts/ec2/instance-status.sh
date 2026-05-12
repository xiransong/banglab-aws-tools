#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_loop3_config
validate_instance_name

instance_id="$(resolve_named_active_instance_id)"

get_named_active_instances_json | jq -r '
  [.Reservations[].Instances[]?][0] as $i
  | "Name: " + (($i.Tags[]? | select(.Key == "Name") | .Value) // "-"),
    "InstanceId: " + $i.InstanceId,
    "State: " + $i.State.Name,
    "InstanceType: " + $i.InstanceType,
    "ImageId: " + $i.ImageId,
    "PublicIp: " + ($i.PublicIpAddress // "-"),
    "PrivateIp: " + ($i.PrivateIpAddress // "-"),
    "LaunchTime: " + $i.LaunchTime,
    "AvailabilityZone: " + $i.Placement.AvailabilityZone,
    "KeyName: " + ($i.KeyName // "-"),
    "SecurityGroups: " + ([$i.SecurityGroups[]? | .GroupName + " (" + .GroupId + ")"] | join(", ")),
    "RootDeviceName: " + ($i.RootDeviceName // "-")
'

info "Resolved instance: ${instance_id}"

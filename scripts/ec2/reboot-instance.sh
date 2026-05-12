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
state="$(get_instance_state "${instance_id}")"

if [[ "${state}" != "running" ]]; then
  die "Instance ${INSTANCE_NAME} is ${state}, not running."
fi

aws_ec2 reboot-instances --instance-ids "${instance_id}" >/dev/null

ok "Reboot requested: ${INSTANCE_NAME} (${instance_id})"

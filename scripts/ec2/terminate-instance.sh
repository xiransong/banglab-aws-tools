#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ec2_config
validate_instance_name
require_config_vars CONFIRM_TERMINATE

if [[ "${CONFIRM_TERMINATE}" != "${INSTANCE_NAME}" ]]; then
  die "Refusing to terminate. Set CONFIRM_TERMINATE=${INSTANCE_NAME} to confirm."
fi

instance_id="$(resolve_named_active_instance_id)"

warn "Terminating deletes the EC2 instance and usually deletes its root EBS volume."
aws_ec2 terminate-instances --instance-ids "${instance_id}" >/dev/null

ok "Terminate requested: ${INSTANCE_NAME} (${instance_id})"

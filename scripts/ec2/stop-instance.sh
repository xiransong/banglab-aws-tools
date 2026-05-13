#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ec2_config
validate_instance_name

instance_id="$(resolve_named_active_instance_id)"

aws_ec2 stop-instances --instance-ids "${instance_id}" >/dev/null

ok "Stop requested: ${INSTANCE_NAME} (${instance_id})"
warn "Stopped instances may still have root EBS storage costs."

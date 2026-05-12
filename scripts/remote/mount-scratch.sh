#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scratch-common.sh
source "${SCRIPT_DIR}/scratch-common.sh"

validate_remote_volume_id
resolve_ebs_device_by_volume_id

fstype="$(get_device_fstype)"

if [[ -z "${fstype}" ]]; then
  die "Device ${REAL_DEVICE} has no filesystem. Run setup-scratch first if this is a new blank volume."
fi

sudo mkdir -p "${SCRATCH_MOUNT}"

uuid="$(get_device_uuid)"
ensure_fstab_entry "${uuid}"

if ! mountpoint -q "${SCRATCH_MOUNT}"; then
  sudo mount "${SCRATCH_MOUNT}"
else
  ok "Already mounted: ${SCRATCH_MOUNT}"
fi

ensure_scratch_owned_by_user
mkdir -p "${SCRATCH_MOUNT}"/{repos,data,outputs,transfer}

ok "Scratch volume mounted: ${SCRATCH_MOUNT}"
info "Next: cd ${SCRATCH_MOUNT}"

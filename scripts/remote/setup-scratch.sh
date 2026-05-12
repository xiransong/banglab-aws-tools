#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scratch-common.sh
source "${SCRIPT_DIR}/scratch-common.sh"

validate_remote_volume_id
resolve_ebs_device_by_volume_id

fstype="$(get_device_fstype)"

if [[ -n "${fstype}" ]]; then
  die "Device ${REAL_DEVICE} already has filesystem ${fstype}. Refusing to format."
fi

echo
echo "========================================"
echo "DANGEROUS OPERATION - DRY RUN"
echo "========================================"
printf 'Volume ID    : %s\n' "${VOLUME_ID}"
printf 'By-id link   : %s\n' "${BY_ID_LINK}"
printf 'Block device : %s\n' "${REAL_DEVICE}"
printf 'Filesystem   : <none>\n'
printf 'Mount point  : %s\n' "${SCRATCH_MOUNT}"
echo
echo "Planned actions:"
printf '  - sudo mkfs.%s %s\n' "${FS_TYPE}" "${REAL_DEVICE}"
printf '  - sudo mkdir -p %s\n' "${SCRATCH_MOUNT}"
printf '  - mount %s at %s\n' "${REAL_DEVICE}" "${SCRATCH_MOUNT}"
echo "  - add UUID-based /etc/fstab entry with nofail"
echo "  - chown scratch mount to current user"
echo "  - create repos, data, outputs, transfer"
echo
echo "ALL EXISTING DATA ON THIS DEVICE WILL BE LOST."
echo "========================================"

if [[ "${CONFIRM_SETUP_SCRATCH:-}" != "YES" ]]; then
  die "Refusing to format. Re-run with CONFIRM_SETUP_SCRATCH=YES"
fi

sudo "mkfs.${FS_TYPE}" "${REAL_DEVICE}"
sudo mkdir -p "${SCRATCH_MOUNT}"

uuid="$(get_device_uuid)"
ensure_fstab_entry "${uuid}"

if ! mountpoint -q "${SCRATCH_MOUNT}"; then
  sudo mount "${SCRATCH_MOUNT}"
fi

ensure_scratch_owned_by_user
mkdir -p "${SCRATCH_MOUNT}"/{repos,data,outputs,transfer}

ok "Scratch volume is ready: ${SCRATCH_MOUNT}"
info "Next: cd ${SCRATCH_MOUNT}"

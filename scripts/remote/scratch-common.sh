#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/log.sh
source "${REPO_ROOT}/scripts/lib/log.sh"

SCRATCH_MOUNT="${SCRATCH_MOUNT:-${HOME}/scratch}"
FS_TYPE="${FS_TYPE:-ext4}"

validate_remote_volume_id() {
  if [[ -z "${VOLUME_ID:-}" ]]; then
    die "Missing required variable: VOLUME_ID"
  fi

  if [[ ! "${VOLUME_ID}" =~ ^vol-[A-Za-z0-9]+$ ]]; then
    die "VOLUME_ID should look like vol-xxxxxxxx."
  fi
}

resolve_ebs_device_by_volume_id() {
  local volume_id_nodash
  local matches
  local by_id_link

  volume_id_nodash="${VOLUME_ID//-/}"

  matches="$(
    ls /dev/disk/by-id/ 2>/dev/null |
      grep "nvme-Amazon_Elastic_Block_Store_${volume_id_nodash}" || true
  )"

  if [[ -z "${matches}" ]]; then
    die "No local block device found for ${VOLUME_ID}. Is the volume attached to this instance?"
  fi

  by_id_link="$(printf '%s\n' "${matches}" | grep -v '_[0-9]\+$' | head -n 1)"
  if [[ -z "${by_id_link}" ]]; then
    by_id_link="$(printf '%s\n' "${matches}" | head -n 1)"
  fi

  BY_ID_LINK="${by_id_link}"
  REAL_DEVICE="$(readlink -f "/dev/disk/by-id/${BY_ID_LINK}")"

  if [[ -z "${REAL_DEVICE}" || ! -b "${REAL_DEVICE}" ]]; then
    die "Resolved device is not a block device: ${REAL_DEVICE:-<empty>}"
  fi
}

get_device_fstype() {
  lsblk -no FSTYPE "${REAL_DEVICE}" | head -n 1
}

get_device_uuid() {
  sudo blkid -s UUID -o value "${REAL_DEVICE}"
}

ensure_fstab_entry() {
  local uuid="$1"

  if ! grep -q "UUID=${uuid}" /etc/fstab; then
    printf 'UUID=%s  %s  %s  defaults,nofail  0  2\n' \
      "${uuid}" \
      "${SCRATCH_MOUNT}" \
      "${FS_TYPE}" | sudo tee -a /etc/fstab >/dev/null
  fi
}

ensure_scratch_owned_by_user() {
  sudo chown "$(id -u):$(id -g)" "${SCRATCH_MOUNT}"
}

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_loop3_config
validate_instance_name

SSH_HOST="${SSH_HOST:-ec2}"
validate_ssh_host

instance_id="$(resolve_named_active_instance_id)"
state="$(get_instance_state "${instance_id}")"

if [[ "${state}" != "running" ]]; then
  die "Instance ${INSTANCE_NAME} is ${state}, not running."
fi

public_ip="$(get_instance_public_ip "${instance_id}")"
if [[ -z "${public_ip}" ]]; then
  die "Instance ${INSTANCE_NAME} does not have a public IP."
fi

ssh_dir="${HOME}/.ssh"
ssh_config="${ssh_dir}/config"
mkdir -p "${ssh_dir}"
chmod 700 "${ssh_dir}"
touch "${ssh_config}"
chmod 600 "${ssh_config}"

begin_marker="# banglab-aws-tools begin ${SSH_HOST}"
end_marker="# banglab-aws-tools end ${SSH_HOST}"
tmp_file="$(mktemp)"
trimmed_file="$(mktemp)"
new_block="$(mktemp)"
trap 'rm -f "${tmp_file}" "${trimmed_file}" "${new_block}"' EXIT

cat >"${new_block}" <<EOF
${begin_marker}
Host ${SSH_HOST}
  HostName ${public_ip}
  User ubuntu
  IdentityFile ${SSH_KEY_PATH}
  IdentitiesOnly yes
${end_marker}
EOF

awk -v begin="${begin_marker}" -v end="${end_marker}" '
  $0 == begin { skipping = 1; next }
  $0 == end { skipping = 0; next }
  !skipping { print }
' "${ssh_config}" >"${tmp_file}"

awk '
  { lines[++count] = $0 }
  END {
    while (count > 0 && lines[count] == "") {
      count--
    }
    for (i = 1; i <= count; i++) {
      print lines[i]
    }
  }
' "${tmp_file}" >"${trimmed_file}"

if awk -v host="${SSH_HOST}" '
  /^[[:space:]]*Host[[:space:]]+/ {
    for (i = 2; i <= NF; i++) {
      if ($i == host) {
        found = 1
      }
    }
  }
  END { exit found ? 0 : 1 }
' "${trimmed_file}"; then
  die "SSH host ${SSH_HOST} already exists outside a banglab-aws-tools managed block. Remove it from ${ssh_config} or choose another SSH_HOST."
fi

{
  cat "${trimmed_file}"
  if [[ -s "${trimmed_file}" ]]; then
    printf '\n'
  fi
  cat "${new_block}"
} >"${ssh_config}"

ok "Updated SSH config: ${ssh_config}"
info "Host: ${SSH_HOST}"
info "HostName: ${public_ip}"
info "Next: ssh ${SSH_HOST}"
info "You can also use ${SSH_HOST} in VS Code Remote SSH."
info "If SSH says connection refused, wait 30-60 seconds and retry."

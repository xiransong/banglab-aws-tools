#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/aws.sh
source "${REPO_ROOT}/scripts/lib/aws.sh"

load_config
validate_ec2_config
validate_instance_name

RETRY_CAPACITY="${RETRY_CAPACITY:-0}"
RETRY_INTERVAL_SECONDS="${RETRY_INTERVAL_SECONDS:-30}"
[[ "${RETRY_CAPACITY}" == "0" || "${RETRY_CAPACITY}" == "1" ]] || die "RETRY_CAPACITY must be 0 or 1."
[[ "${RETRY_INTERVAL_SECONDS}" =~ ^[1-9][0-9]*$ ]] || die "RETRY_INTERVAL_SECONDS must be a positive integer."

instance_id="$(resolve_named_active_instance_id)"
error_file="$(mktemp)"
trap 'rm -f "${error_file}"' EXIT

while true; do
  if aws_ec2 start-instances --instance-ids "${instance_id}" >/dev/null 2>"${error_file}"; then
    break
  else
    status=$?
  fi
  cat "${error_file}" >&2
  if [[ "${RETRY_CAPACITY}" != "1" ]] || ! grep -q 'An error occurred (InsufficientInstanceCapacity)' "${error_file}"; then
    exit "${status}"
  fi
  warn "Insufficient capacity. Retrying in ${RETRY_INTERVAL_SECONDS} seconds; press Ctrl-C to stop."
  sleep "${RETRY_INTERVAL_SECONDS}"
done

ok "Start requested: ${INSTANCE_NAME} (${instance_id})"
info "Waiting for instance to reach running..."

attempts=0
max_attempts=60

while true; do
  state="$(get_instance_state "${instance_id}")"
  if [[ "${state}" == "running" ]]; then
    break
  fi
  if [[ "${state}" == "shutting-down" || "${state}" == "terminated" ]]; then
    die "Instance ${instance_id} reached unexpected state while starting: ${state}"
  fi
  attempts=$((attempts + 1))
  if [[ "${attempts}" -ge "${max_attempts}" ]]; then
    die "Timed out waiting for instance ${instance_id} to reach running. Current state: ${state}"
  fi
  info "${state}..."
  sleep 10
done

public_ip="$(get_instance_public_ip "${instance_id}")"

ok "Instance is running: ${INSTANCE_NAME} (${instance_id})"
info "Public IP: ${public_ip:-<missing>}"

#!/usr/bin/env bash

_log_prefix() {
  local stream="$1"
  local color="$2"
  local label="$3"

  if [[ -t "${stream}" ]]; then
    printf '\033[%sm[%s]\033[0m' "${color}" "${label}"
  else
    printf '[%s]' "${label}"
  fi
}

info() {
  _log_prefix 1 "36" "INFO"
  printf ' %s\n' "$*"
}

ok() {
  _log_prefix 1 "32" "OK"
  printf ' %s\n' "$*"
}

warn() {
  _log_prefix 2 "33" "WARN" >&2
  printf ' %s\n' "$*" >&2
}

fail() {
  _log_prefix 2 "31" "ERROR" >&2
  printf ' %s\n' "$*" >&2
}

die() {
  fail "$*"
  exit 1
}

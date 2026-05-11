#!/usr/bin/env bash

check_command() {
  local cmd="$1"

  if command -v "${cmd}" >/dev/null 2>&1; then
    ok "${cmd} found: $(command -v "${cmd}")"
    return 0
  fi

  fail "${cmd} not found"
  return 1
}

check_aws_cli_v2() {
  if ! command -v aws >/dev/null 2>&1; then
    fail "aws not found"
    return 1
  fi

  local version
  version="$(aws --version 2>&1 || true)"

  if [[ "${version}" == aws-cli/2* ]]; then
    ok "AWS CLI v2 found: ${version}"
    return 0
  fi

  fail "AWS CLI v2 required, found: ${version}"
  return 1
}

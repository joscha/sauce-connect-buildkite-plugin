#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment these for debug output about stubbed commands
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
# export SC_STUB_DEBUG=/dev/tty
# export MY_COMMAND_STUB_DEBUG=/dev/tty

export IS_UNDER_TEST=true

setup() {
  export TMP_DIR=$(mktemp -d)
  stub buildkite-agent \
    "artifact upload sauce-connect.*.log : echo 'Uploaded sauce-connect.*.log artifacts'"
}

teardown() {
  rm -rf "${TMP_DIR}"
  unset TMP_DIR
}

stub_sc() {
  local tmp_dir="$1"
  local sauce_username="$2"
  local sauce_access_key="$3"
  local tunnel_identifier="$4"
  local sauce_connect_version="${5:-latest}"
  local attempts="${6:-1}"
  local exec="${7:-"echo sc connect"}"

  local args=( )
  local attempt
  for (( attempt=1; attempt<="${attempts}"; attempt++ )); do
    args+=( "-u ${sauce_username} -k ${sauce_access_key} --tunnel-identifier ${tunnel_identifier} --readyfile ${TMP_DIR}/ready.${attempt} --pidfile ${TMP_DIR}/pid.${attempt} --logfile ${TMP_DIR}/sauce-connect.${attempt}.log --verbose : ${exec} ${attempt}" )
  done

  stub sc "${args[@]}"
}

@test "Command fails if SAUCE_USERNAME is not set" {
  export SAUCE_USERNAME=""
  export SAUCE_ACCESS_KEY=""

  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "SAUCE_USERNAME not set"

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
}

@test "Command fails if SAUCE_ACCESS_KEY is not set" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY=""
  
  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "SAUCE_ACCESS_KEY not set"

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
}

@test "Command fails if BUILDKITE_JOB_ID is not set when invoked without a tunnel identifier" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"

  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "BUILDKITE_JOB_ID not set"

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
}

@test "Command uses BUILDKITE_PLUGIN_SAUCE_CONNECT_TUNNEL_IDENTIFIER as tunnel identifier" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_PLUGIN_SAUCE_CONNECT_TUNNEL_IDENTIFIER="my-config-identifier"
  export BUILDKITE_JOB_ID="my-job-id"
  
  touch "${TMP_DIR}/ready.1"

  stub_sc \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_PLUGIN_SAUCE_CONNECT_TUNNEL_IDENTIFIER}"

  run "${PWD}/hooks/command"

  assert_success

  unstub sc

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_PLUGIN_SAUCE_CONNECT_TUNNEL_IDENTIFIER
  unset BUILDKITE_JOB_ID
}

@test "Command uses BUILDKITE_JOB_ID as tunnel identifier fallback" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_JOB_ID="my-job-id"

  touch "${TMP_DIR}/ready.1"

  stub_sc \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_JOB_ID}"

  run "${PWD}/hooks/command"

  assert_success

  unstub sc

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
}

@test "Command fails for unknown OSes" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_JOB_ID="my-job-id"
  local ORIGINAL_OSTYPE="${OSTYPE}"
  export OSTYPE="fancy-arch"

  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "unknown OS: ${OSTYPE}"

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
  export OSTYPE="${ORIGINAL_OSTYPE}"
}

@test "Command runs BUILDKITE_COMMAND after the tunnel has been started" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_JOB_ID="my-job-id"
  export BUILDKITE_COMMAND="my-command foo"

  touch "${TMP_DIR}/ready.1"

  stub_sc \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_JOB_ID}"

  stub my-command "foo : echo 'All systems green'"

  run "${PWD}/hooks/command"

  assert_success
  assert_output --partial "sauce-connect is up \o/"
  assert_output --partial "All systems green"

  unstub sc
  unstub my-command

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
  unset BUILDKITE_COMMAND
}

attempts=3

@test "Command tries ${attempts} times to start tunnel" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_JOB_ID="my-job-id"

  stub_sc \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_JOB_ID}" \
    "latest" \
    "${attempts}"

  stub sleep

  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "Failed to connect!"
  assert_output --partial "sauce-connect timed out!"
  assert_output --partial "(Attempt 1)"
  assert_output --partial "sc connect 1"
  assert_output --partial "(Attempt 2)"
  assert_output --partial "sc connect 2"
  assert_output --partial "(Attempt 3)"
  assert_output --partial "sc connect 3"
  assert_output --partial "Uploaded sauce-connect.*.log artifacts"

  unstub sc

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
}
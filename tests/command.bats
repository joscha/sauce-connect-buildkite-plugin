#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment these for debug output about stubbed commands
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
# export DOCKER_STUB_DEBUG=/dev/tty
# export MY_COMMAND_STUB_DEBUG=/dev/tty

setup() {
  export TMP_DIR=$(mktemp -d)
  stub buildkite-agent \
    "artifact upload sauce-connect.*.log : echo 'Uploaded sauce-connect.*.log artifacts'"
}

teardown() {
  rm -rf "${TMP_DIR}"
  unset TMP_DIR
}

stub_docker() {
  local tmp_dir="$1"
  local sauce_username="$2"
  local sauce_access_key="$3"
  local tunnel_identifier="$4"
  local sauce_connect_version="${5:-latest}"
  local attempts="${6:-1}"

  local args=( )
  local attempt
  for (( attempt=1; attempt<="${attempts}"; attempt++ )); do
    args+=( "run -d -p 8000:8000 -v ${tmp_dir}:/tmp ustwo/sauce-connect:${sauce_connect_version} -P 8000 -u ${sauce_username} -k ${sauce_access_key} --tunnel-identifier ${tunnel_identifier} --readyfile /tmp/ready --logfile /tmp/sauce-connect.${attempt}.log : echo c0ffee-${attempt}" )
  done

  stub docker "${args[@]}"
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
  
  touch "${TMP_DIR}/ready"

  stub_docker \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_PLUGIN_SAUCE_CONNECT_TUNNEL_IDENTIFIER}"

  run "${PWD}/hooks/command"

  assert_success
  assert_output --partial "Using tunnel-identifier: 'my-config-identifier'"

  unstub docker

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_PLUGIN_SAUCE_CONNECT_TUNNEL_IDENTIFIER
  unset BUILDKITE_JOB_ID
}

@test "Command uses BUILDKITE_JOB_ID as tunnel identifier fallback" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_JOB_ID="my-job-id"

  touch "${TMP_DIR}/ready"

  stub_docker \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_JOB_ID}"

  run "${PWD}/hooks/command"

  assert_success
  assert_output --partial "Using tunnel-identifier: 'my-job-id'"

  unstub docker

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
}

@test "Command runs BUILDKITE_COMMAND after the tunnel has been started" {
  export SAUCE_USERNAME="my-username"
  export SAUCE_ACCESS_KEY="my-access-key"
  export BUILDKITE_JOB_ID="my-job-id"
  export BUILDKITE_COMMAND="my-command foo"

  touch "${TMP_DIR}/ready"

  stub_docker \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_JOB_ID}"

  stub my-command "foo : echo 'All systems green'"

  run "${PWD}/hooks/command"

  assert_success
  assert_output --partial "sauce-connect is up \o/"
  assert_output --partial "All systems green"

  unstub docker
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

  stub_docker \
    "${TMP_DIR}" \
    "${SAUCE_USERNAME}" \
    "${SAUCE_ACCESS_KEY}" \
    "${BUILDKITE_JOB_ID}" \
    "latest" \
    "${attempts}"

  local attempt
  for attempt in {1..$attempts}; do
    local i
    for i in {1..60}; do
      stub sleep 2
    done
  done

  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "error: sauce-connect failed!"
  assert_output --partial "waiting for readyfile (120s)"
  assert_output --partial "sauce-connect timed out!"
  assert_output --partial "Docker process: c0ffee-1"
  assert_output --partial "attempt 1"
  assert_output --partial "Docker process: c0ffee-2"
  assert_output --partial "attempt 2"
  assert_output --partial "Docker process: c0ffee-3"
  assert_output --partial "attempt 3"
  assert_output --partial "Uploaded sauce-connect.*.log artifacts"

  unstub docker

  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
}
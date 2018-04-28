#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

ORIGINAL_SAUCE_USERNAME="${SAUCE_USERNAME}"
ORIGINAL_SAUCE_ACCESS_KEY="${SAUCE_ACCESS_KEY}"

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

# The following tests need actual saucelabs credentials via SAUCE_ACCESS_KEY and SAUCE_USERNAME

@test "Command uses BUILDKITE_JOB_ID as tunnel identifier fallback" {
  export SAUCE_USERNAME="${ORIGINAL_SAUCE_USERNAME}"
  export SAUCE_ACCESS_KEY="${ORIGINAL_SAUCE_ACCESS_KEY}"
  export BUILDKITE_JOB_ID="my-job-id"

  stub docker \
    "run -it --rm --volume $PWD:/app --workdir /app --env BUILDKITE_JOB_ID  --env SAUCE_USERNAME --env SAUCE_ACCESS_KEY image:tag bash -c 'command1 \"a string\"' : echo ran command in docker"

  run "${PWD}/hooks/command"

  assert_failure
  assert_output --partial "Sauce Connect is up, you may start your tests."

  unstub docker
  unset SAUCE_USERNAME
  unset SAUCE_ACCESS_KEY
  unset BUILDKITE_JOB_ID
}
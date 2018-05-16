#!/usr/bin/env bash

REPO_DIR=$(git rev-parse --show-toplevel)

pushd "${REPO_DIR}" >/dev/null

docker run \
  -it \
  --rm \
  -v "$(pwd):/plugin" \
  buildkite/plugin-linter \
    --id joscha/sauce-connect

popd >/dev/null
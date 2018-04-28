#!/usr/bin/env bash

REPO_DIR=$(git rev-parse --show-toplevel)

pushd "${REPO_DIR}" >/dev/null

docker run \
  --volume "$(pwd)":/src/ \
  --workdir=/src \
  --tty \
  --rm \
  koalaman/shellcheck hooks/*

popd >/dev/null

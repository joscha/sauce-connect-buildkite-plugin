# Sauce Connect Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that opens a [sauce-connect tunnel](https://wiki.saucelabs.com/display/DOCS/Sauce+Connect+Proxy).

It contains a [command hook](hooks/command), and [tests](tests/command.bats) using [plugin-tester](https://github.com/buildkite-plugins/plugin-tester).

It uses the [ustwo/docker-sauce-connect](https://github.com/ustwo/docker-sauce-connect) docker image.

## Example

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      sauce-connect#v1.0.0: ~
```

## Configuration

### `tunnel-identifier` (optional)

The tunnel identifier to use, by default it will use the Buildkite Job ID (`BUILDKITE_JOB_ID`)

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      sauce-connect#v1.0.0:
        tunnel-identifier: "my-custom-tunnel-id"
```

### `sauce-connect-version` (optional)

The Sauce Connect version to use, available versions, see [here](https://hub.docker.com/r/ustwo/sauce-connect/tags/). Defaults to `"latest"`.

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      sauce-connect#v1.0.0:
        sauce-connect-version: "4.4"
```

## Tests

To run the tests, run:
```sh
docker-compose run --rm tests
```

## Lint

### The plugin
```sh
docker run \
  -it \
  --rm \
  -v "$(pwd):/plugin" \
  buildkite/plugin-linter \
    --name sauce-connect
```

### The shell files
```sh
docker run \
  --volume "$(pwd)":/src/ \
  --workdir=/src \
  --tty \
  --rm \
  koalaman/shellcheck hooks/*
```

## License

MIT (see [LICENSE](LICENSE))

# Sauce Connect Buildkite Plugin [![Build Status](https://travis-ci.org/joscha/sauce-connect-buildkite-plugin.svg?branch=master)](https://travis-ci.org/joscha/sauce-connect-buildkite-plugin)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that opens a [sauce-connect tunnel](https://wiki.saucelabs.com/display/DOCS/Sauce+Connect+Proxy).

It contains a [command hook](hooks/command), and [tests](tests/command.bats) using [plugin-tester](https://github.com/buildkite-plugins/plugin-tester).

## Example

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      joscha/sauce-connect#v2.0.0: ~
```

## Configuration

### `tunnel-identifier` (optional)

The tunnel identifier to use, by default it will use the Buildkite Job ID (`BUILDKITE_JOB_ID`)

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      joscha/sauce-connect#v2.0.0:
        tunnel-identifier: "my-custom-tunnel-id"
```

### `sauce-connect-version` (optional)

The Sauce Connect version to use, available versions, see [here](https://wiki.saucelabs.com/display/DOCS/Sauce+Connect+Proxy).

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      joscha/sauce-connect#v2.0.0:
        sauce-connect-version: "4.4.12"
```

## Tests

To run the tests, run `.ci/test.sh`

## Lint

* Plugin: `.ci/lint-plugin.sh`
* Shell files `.ci/lint-shell.sh`

## License

MIT (see [LICENSE](LICENSE))

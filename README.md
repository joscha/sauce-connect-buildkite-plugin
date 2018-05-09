# Sauce Connect Buildkite Plugin [![Build Status](https://travis-ci.org/joscha/sauce-connect-buildkite-plugin.svg?branch=master)](https://travis-ci.org/joscha/sauce-connect-buildkite-plugin)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that opens a [sauce-connect tunnel](https://wiki.saucelabs.com/display/DOCS/Sauce+Connect+Proxy).

It contains a [command hook](hooks/command), and [tests](tests/command.bats) using [plugin-tester](https://github.com/buildkite-plugins/plugin-tester).

## Example

It looks like this on success:

<img width="538" alt="sauce-connect success" src="https://user-images.githubusercontent.com/188038/39405935-18b34c88-4bf2-11e8-9e4e-a9f3bb0f6166.png">
And like this on a connection failure:

<img width="876" alt="sauce-connect failure" src="https://user-images.githubusercontent.com/188038/39405948-4770f12e-4bf2-11e8-9fa0-e64b54323536.png">

## Usage

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      joscha/sauce-connect#v2.0.1: ~
```

## Configuration

### `tunnel-identifier` (optional)

The tunnel identifier to use, by default it will use the Buildkite Job ID (`BUILDKITE_JOB_ID`)

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      joscha/sauce-connect#v2.0.1:
        tunnel-identifier: "my-custom-tunnel-id"
```

### `sauce-connect-version` (optional)

The Sauce Connect version to use, available versions, see [here](https://wiki.saucelabs.com/display/DOCS/Sauce+Connect+Proxy).

```yml
steps:
  - command: 'yarn && yarn saucelabs-based-tests'
    plugins:
      joscha/sauce-connect#v2.0.1:
        sauce-connect-version: "4.4.12"
```

## Tests

To run the tests, run `.ci/test.sh`

## Lint

* Plugin: `.ci/lint-plugin.sh`
* Shell files `.ci/lint-shell.sh`

## License

MIT (see [LICENSE](LICENSE))

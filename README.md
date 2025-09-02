# neotest-jest

[![build](https://github.com/haydenmeade/neotest-jest/actions/workflows/workflow.yaml/badge.svg)](https://github.com/haydenmeade/neotest-jest/actions/workflows/workflow.yaml)

This plugin provides a [jest](https://github.com/jestjs/jest) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
Requires at least Neotest version 4.0.0 which in turn requires at least neovim version 0.9.0.

**It is currently a work in progress**.

## Installation

Using packer:

```lua
use({
  "nvim-neotest/neotest",
  requires = {
    ...,
    "nvim-neotest/neotest-jest",
  }
  config = function()
    require("neotest").setup({
      ...,
      adapters = {
        require("neotest-jest")({
          jestCommand = "npm test --",
          jestArguments = function(defaultArguments, context)
            return defaultArguments
          end,
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
          isTestFile = require("neotest-jest.jest-util").defaultIsTestFile,
        }),
      }
    })
  end
})
```

Make sure you have the appropriate `treesitter` language parsers installed otherwise no tests will be found:

```
:TSInstall javascript
```
You might want to install `tsx` and `typescript` parser as well depending on your project.

## Configuration

#### `jestCommand`

Type: `string | fun(path: string): string`

The jest command to run when running tests. Can also be a function that accepts
the path to the current neotest position and returns the command to run.
`neotest-jest` will attempt to resolve it automatically if not given.

* Example: `"npm test --"`

#### `jestArguments`

Type: `fun(defaultArguments: string[], jestArgsContext: neotest-jest.JestArgumentContext): string[]`

The arguments to pass to jest when running tests.

The function is called with the default arguments and a context table that
contains a `config: string?` entry for the config file (normally passed to the
`--config` option) or `nil` if none was found, a `resultsPath` entry for the
destination file for writing json test output (normally passed to the
`--outputFile` option), and a `testNamePattern` entry for the regex pattern for
tests (normally passed to the `--testNamePattern` option). It should return the
final arguments as a `string[]`.

> [!WARNING]  
> Make sure to always pass the following options:

* `--forceExit`: Ensure jest and thus the adapter does not hang
* `--testLocationInResults`: Ensure jest outputs test locations
* `--json`: Output test results in json
* `--outputFile`: The location for writing json output

The default function for `jestArguments` can be obtained by calling
`require("neotest-jest.jest-util").getJestArguments`. The test file is
automatically added to the end of the jest arguments by `neotest-jest`.

#### `jestConfigFile`

Type: `string | fun(file_path: string): string`

Path to a jest config file or a function taking the path of the current neotest
position and returning a path to a jest config file. Defaults to
`"jest.config.js"`.

* Example: `"custom.jest.ts"`

#### `env`

Type: `table<string, string> | fun(): table<string, string>`

A key-value map of environment variables to set or a function returning such a map.

* Example: `{ CI = true }`

#### `cwd`

Type: `string | fun(): string`

The current working directory to use or a function returning the current working
directory.

* Example: `function() return vim.fn.getcwd() end`

#### `strategy_config`

The [`nvim-dap`](https://github.com/mfussenegger/nvim-dap) strategy
configuration to use when debugging tests.

#### `jest_test_discovery`

Whether to discover parametrized tests such as those run with
`it.each`/`test.each`. See [Parameterized tests](#parameterized-tests) for more
info.

* Example: `jest_test_discovery = true`

#### `isTestFile`

If set, overrides the check for determining if a file is a test file or not. The
default behaviour will match the file path with a predefined set of patterns and
require jest to be installed as a dependency via `dependencies` or
`devDependencies`, or if a value in `scripts` is exactly `'jest'` in the
`package.json`.

> [!WARNING]
> The `isTestFile` function runs in an async context so you cannot call
> functions that cannot be called in fast events (see `:h vim.in_fast_event()`)

Example:

```lua
---@async
---@param file_path string?
---@return boolean
isTestFile = function(file_path)
  if not file_path then
    return false
  end

  return vim.fn.fnamemodify(file_path, ":e:e") == "testy.js"
end
```

You can access the default `isTestFile` function via
`require("neotest-jest.jest-util").defaultIsTestFile`, the default test file
matcher via `require("neotest-jest.util").defaultTestFileMatcher`, and the
default check for a jest dependency via
`require("neotest-jest.jest-util").hasJestDependency`

## Usage

See neotest's documentation for more information on how to run tests.

### Running tests in watch mode

`jest` allows to run your tests in [watch mode](https://jestjs.io/docs/cli#--watch).
To run test in this mode you either can enable it globally in the setup:

```lua
require('neotest').setup({
  ...,
  adapters = {
    require('neotest-jest')({
      jestCommand = require('neotest-jest.jest-util').getJestCommand(vim.fn.expand '%:p:h') .. ' --watch',
    }),
  }
})
```

or add a specific keymap to run tests with watch mode:

```lua
vim.api.nvim_set_keymap("n", "<leader>tw", "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>", {})
```

### Parameterized tests

If you want to allow to `neotest-jest` to discover parameterized tests you need to enable flag
`jest_test_discovery` in config setup:
```lua
require('neotest').setup({
  ...,
  adapters = {
    require('neotest-jest')({
      ...,
      jest_test_discovery = false,
    }),
  }
})
```
Its also recommended to disable `neotest` `discovery` option like this:
```lua
require("neotest").setup({
	...,
	discovery = {
		enabled = false,
	},
})
```
because `jest_test_discovery` runs `jest` command on file to determine
what tests are inside the file. If `discovery` would be enabled then `neotest-jest`
would spawn a lot of procesees.

### Monorepos

If you have a monorepo setup, you might have to do a little more configuration, especially if
you have different jest configurations per package.

```lua
jestConfigFile = function(file)
  if file:find("/packages/") then
    -- Matches "some/path/" in "some/path/src/"
    local match = file:match("(.*/[^/]+/)src")

    if match then
      return match .. "jest.config.ts"
    end
  end

  return vim.fn.getcwd() .. "/jest.config.ts"
end,
```

Also, if your monorepo set up requires you to run a specific test file with cwd on the package
directory (like when you have a lerna setup for example), you might also have to tweak things a
bit:

```lua
cwd = function(file)
  if file:find("/packages/") then
    -- Matches "some/path/" in "some/path/src/"
    local match = file:match("(.*/[^/]+/)src")

    if match then
      return match
    end
  end

  return vim.fn.getcwd()
end
```

## :gift: Contributing

Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example spec that can be tested.

To run the tests and styling:

1. Fork this repository.
2. Make changes.
3. Make sure tests and styling checks are passing. You will need to install jest
   and make sure it is available as a command in order to run the tests since it
   tests parametrized tests which require running a jest command. It should
   suffice to run `npm install` in the `./spec` directory.
   * Run tests by running `./scripts/test` in the root directory. Running the tests requires [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim). You may need to update the paths in `./tests/minimal_init.lua` to point to your local installation.
   * If you are testing a new feature that requires running tests then please
     run `cd spec/`, open a test file, and make sure things work.
   * Install [stylua](https://github.com/JohnnyMorganz/StyLua) and check styling using `stylua --check lua/ tests/`. Omit `--check` in order to fix styling.
4. Submit a pull request.
5. Get it approved.

## Bug Reports

Please file any bug reports and I _might_ take a look if time permits otherwise please submit a PR, this plugin is intended to be by the community for the community.

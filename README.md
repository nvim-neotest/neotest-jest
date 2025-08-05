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

## Usage

See neotest's documentation for more information on how to run tests.

### Options

#### `jestCommand`

The jest base command to use to run tests. Will attempt to resolve it
automatically if not given.

* Example: `"npm test --"`

#### `jestConfigFile`

The path to the jest config file to use. Will use either `jest.config.js` or
`jest.config.ts` if present.

* Example: `"custom.jest.ts"`

#### `env`

A table of environment variables to set when running tests.

* Example: `{ CI = true }`

#### `cwd`

The working directory to use when running tests.

* Example: `function() return vim.fn.getCwd() end`

#### `strategy_config`

The strategy config for debugging tests with [`nvim-dap`]().

* Example:

```lua
---@param strategy string
---@param command string[]
---@param cwd string?
function(strategy, command, cwd)
  return {
    name = "Debug Jest Tests",
    type = "pwa-node",
    request = "launch",
    args = { unpack(command, 2) },
    runtimeExecutable = command[1],
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
    rootPath = "${workspaceFolder}",
    cwd = cwd or "${workspaceFolder}",
  }
end
```

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
  if string.find(file, "/packages/") then
    return string.match(file, "(.-/[^/]+/)src") .. "jest.config.ts"
  end

  return vim.fn.getcwd() .. "/jest.config.ts"
end,
```

Also, if your monorepo set up requires you to run a specific test file with cwd on the package
directory (like when you have a lerna setup for example), you might also have to tweak things a
bit:

```lua
cwd = function(file)
  if string.find(file, "/packages/") then
    return string.match(file, "(.-/[^/]+/)src")
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
   * Run tests by running `./scripts/test` in the root directory. Running the tests requires [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim). You may need to update the paths in `./tests/init.vim` to point to your local installation.
   * Install [stylua](https://github.com/JohnnyMorganz/StyLua) and check styling using `stylua --check lua/ tests/`. Omit `--check` in order to fix styling.
4. Submit a pull request.
5. Get it approved.

## Bug Reports

Please file any bug reports and I _might_ take a look if time permits otherwise please submit a PR, this plugin is intended to be by the community for the community.

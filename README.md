# neotest-jest

[![build](https://github.com/haydenmeade/neotest-jest/actions/workflows/workflow.yaml/badge.svg)](https://github.com/haydenmeade/neotest-jest/actions/workflows/workflow.yaml)

This plugin provides a jest adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
**It is currently a work in progress**. It will be transferred to the official neotest organisation (once it's been created).

## Installation

Using packer:

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    ...,
    'haydenmeade/neotest-jest',
  }
  config = function()
    require('neotest').setup({
      ...,
      adapters = {
        require('neotest-jest')({
          jestCommand = "npm test --",
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
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
      jestCommand = "jest --watch ",
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

## :gift: Contributing

Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example spec that can be tested.

To trigger the tests for the adapter, run:

```sh
./scripts/test
```

## Bug Reports

Please file any bug reports and I _might_ take a look if time permits otherwise please submit a PR, this plugin is intended to be by the community for the community.

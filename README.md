# neotest-jest

[![build](https://github.com/haydenmeade/neotest-jest/actions/workflows/workflow.yaml/badge.svg)](https://github.com/haydenmeade/neotest-jest/actions/workflows/workflow.yaml)

This plugin provides a [jest](https://github.com/jestjs/jest) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
Requires at least Neotest version 4.0.0 which in turn requires at least neovim version 0.9.0.

**It is currently a work in progress**.

## Installation

Using packer:

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    ...,
    'nvim-neotest/neotest-jest',
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
      jest_test_discovery = true,
    }),
  }
})
```
It's also recommended to disable `neotest` `discovery` option like this:
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

### Custom test extensions

If the default test extensions don't match your test patterns, you can provide
your own:

```lua
require('neotest').setup({
    ...,
    adapters = {
      require('neotest-jest')({
        ...,
        extension_test_file_match = require('neotest-jest.util').create_test_file_extensions_matcher({ "perf", "spec" }, { "ts", "tsx" })
      }),
    }
})
```

The call to `create_test_file_extensions_matcher` will return a function that will match
`".perf.ts"`, `".perf.tsx"`, `".spec.ts"`, and `".spec.tsx"` test patterns.

Note that the default test extensions won't be used for matching anymore. If you
want to extend the defaults, you can retrieve them.

```lua
local intermediate_extensions, extensions =
require('neotest-jest.util').default_test_extensions()
```

Here, `intermediate_extensions` are the extensions like `perf` and `spec` and
`extensions` is `ts` and `tsx` in the example above.

## :gift: Contributing

Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example spec that can be tested.

To trigger the tests for the adapter, run:

```sh
./scripts/test
```

## Bug Reports

Please file any bug reports and I _might_ take a look if time permits otherwise please submit a PR, this plugin is intended to be by the community for the community.

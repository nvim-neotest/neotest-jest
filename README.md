# neotest-jest

This plugin provides a jest adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
**It is currently a work in progress**. It will be transferred to the official neotest organisation (once it's been created).

## Installation

Using packer:

```lua
use({
  'rcarriga/neotest',
  requires = {
    ...,
    'haydenmeade/neotest-jest',
  }
  config = function()
    require('neotest').setup({
      ...,
      adapters = {
        require('neotest-jest'),
      }
    })
  end
})
```

## Usage

See neotest's documentation for more information on how to run tests.

## Feature requests

Please do note that _I do not intend to implement feature requests_, this repo is an initial starting point for the nvim js/ts/jest community.
Hopefully once it is more stable users will be able to contribute to the project_. For my own part I only intend to implement functionality that
I use in daily workflow.

## Bug Reports

Please file any bug reports and I _might_ take a look if time permits otherwise please submit a PR, this plugin is intended to be by the community for the community.

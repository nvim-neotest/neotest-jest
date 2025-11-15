# Contributing

Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please try to include some minimal reproduction code that can be tested.

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

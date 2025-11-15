describe("adapter.build_spec", function()
  local async = require("nio").tests
  local stub = require("luassert.stub")
  local Tree = require("neotest.types").Tree
  local jest_util = require("neotest-jest.jest-util")
  local util = require("neotest-jest.util")
  local test_utils = require("neotest-jest.test-utils")

  test_utils.prepare_vim_treesitter()

  require("neotest-jest-assertions")

  before_each(function()
    assert:set_parameter("TableFormatLevel", 10)
    stub(vim, "notify")
  end)

  after_each(function()
    ---@diagnostic disable-next-line: undefined-field
    vim.notify:revert()
  end)

  async.it("builds command for file test", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({ tree = tree })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--verbose")
    assert.contains(command, "--json")
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--forceExit")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("builds command for namespace", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({ tree = tree:children()[1] })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=^describe text")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("builds command for nested namespace", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/nestedDescribe.test.ts"
    local positions = adapter.discover_positions(path):to_list()

    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec = adapter.build_spec({ tree = tree:children()[1]:children()[1]:children()[1] })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=^outer middle inner")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("builds correct command for test name with '", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/nestedDescribe.test.ts"
    local positions = adapter.discover_positions(path):to_list()

    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec =
      adapter.build_spec({ tree = tree:children()[1]:children()[1]:children()[1]:children()[2] })

    assert.is.truthy(spec)

    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=^outer middle inner this has a \\'$")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  describe("parameterized test names", function()
    before_each(function()
      -- Mock neotest process run to not run jest test discovery
      stub(require("neotest.lib").process, "run")
    end)

    after_each(function()
      require("neotest.lib").process.run:revert()
    end)

    for index, test_data in ipairs({
      { expected_name = "^describe text test with percent .*$" },
      {
        expected_name = "^describe text test with all of the parameters .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .*$",
      },
      { expected_name = "^describe text test with .*$" },
      { expected_name = "^describe text test with .* and .*$" },
      { expected_name = "^describe text test with .*$" },
      { expected_name = "^describe text test with .* and \\(parenthesis\\)$" },
    }) do
      async.it("builds command with correct test name pattern " .. index, function()
        local adapter = require("neotest-jest")({ jestCommand = "jest" })
        local positions = adapter.discover_positions("./spec/tests/parameterized.test.ts"):to_list()
        local tree = Tree.from_list(positions, function(pos)
          return pos.id
        end)

        local spec = adapter.build_spec({ tree = tree:children()[1]:children()[index] })

        assert.contains(spec.command, "--testNamePattern=" .. test_data.expected_name)
        assert.stub(vim.notify).was_not_called()
      end)
    end
  end)

  async.it("builds command for file test with extra arguments", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions("./spec/tests/basic.test.ts"):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec = adapter.build_spec({
      tree = tree,
      extra_args = { "--clearCache", "--updateSnapshot" },
    })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--clearCache")
    assert.contains(command, "--updateSnapshot")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("builds command for file test without extra arguments if not a list", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions("./spec/tests/basic.test.ts"):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec = adapter.build_spec({
      tree = tree,
      extra_args = { arg1 = "--clearCache", arg2 = "--updateSnapshot" },
    })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=.*")
    assert._not.contains(command, "--clearCache")
    assert._not.contains(command, "--updateSnapshot")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert
      .stub(vim.notify)
      .was_called_with("Extra arguments must be a list, got 'table'", vim.log.levels.ERROR)
  end)

  async.it("builds command for file test with jestCommand arg", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({ tree = tree, jestCommand = "jest --watch" })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--watch")
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("builds command with overridden jest arguments", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestArguments = function(defaultArguments)
        local options = vim.tbl_filter(function(arg)
          return arg ~= "--no-coverage"
        end, defaultArguments)

        return vim.list_extend(options, { "--coverage", "--clearCache" })
      end,
    })

    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({ tree = tree })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert._not.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--verbose")
    assert.contains(command, "--json")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--coverage")
    assert.contains(command, "--clearCache")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("builds command with overridden jest arguments and extra_args", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestArguments = function(defaultArguments)
        local options = vim.tbl_filter(function(arg)
          return arg ~= "--no-coverage"
        end, defaultArguments)

        return vim.list_extend(options, { "--coverage", "--clearCache" })
      end,
    })

    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({
      tree = tree,
      extra_args = { "--useStderr", "--updateSnapshot" },
    })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert._not.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--verbose")
    assert.contains(command, "--json")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--coverage")
    assert.contains(command, "--clearCache")
    assert.contains(command, "--useStderr")
    assert.contains(command, "--updateSnapshot")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.stub(vim.notify).was_not_called()
  end)

  async.it("handles incorrect jest arguments returned by function", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestArguments = function()
        return "hello"
      end,
    })

    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({ tree = tree })

    assert.is.truthy(spec)
    local command = spec.command

    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--verbose")
    assert.contains(command, "--json")
    assert.contains(command, "--config=./spec/jest.config.ts")
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--forceExit")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert
      .stub(vim.notify)
      .was_called_with("Jest arguments must be a list, got 'string'", vim.log.levels.ERROR)
  end)

  async.it("builds command with custom binary and config overrides", function()
    local binary_override = function()
      return "mybinaryoverride"
    end

    local config_override = function()
      return "./spec/jest.config.ts"
    end

    local adapter = require("neotest-jest")({
      jestCommand = binary_override,
      jestConfigFile = config_override,
      jestArguments = jest_util.getJestArguments,
      env = { override = "override", adapter_override = true },
    })

    local path = "./spec/tests/basic.test.ts"
    local positions = adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = adapter.build_spec({ nil, { env = { spec_override = true } }, tree = tree })

    assert.is.truthy(spec)

    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, binary_override())
    assert.contains(command, "--json")
    assert.contains(command, "--verbose")
    assert.contains(command, "--no-coverage")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--config=" .. config_override())
    assert.contains(command, "--testNamePattern=.*")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.is.same(
      spec.env,
      { override = "override", adapter_override = true, spec_override = true }
    )

    assert.stub(vim.notify).was_not_called()
  end)
end)

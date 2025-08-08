describe("adapter.build_spec", function()
  local async = require("nio").tests
  local stub = require("luassert.stub")
  local Tree = require("neotest.types").Tree
  local jest_util = require("neotest-jest.jest-util")
  local util = require("neotest-jest.util")

  require("neotest-jest-assertions")

  async.it("builds command for file test", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/basic.test.ts"
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
  end)

  async.it("builds command for namespace", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/basic.test.ts"
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
  end)

  async.it("builds command for nested namespace", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/nestedDescribe.test.ts"
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
  end)

  async.it("builds correct command for test name with ' ", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/nestedDescribe.test.ts"
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
  end)

  describe("parameterized test names", function()
    for _, test_data in ipairs({
      { index = 1, expected_name = "^describe text test with percent .*$" },
      {
        index = 2,
        expected_name = "^describe text test with all of the parameters .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .*$",
      },
      { index = 3, expected_name = "^describe text test with .*$" },
      { index = 4, expected_name = "^describe text test with .* and .*$" },
      { index = 5, expected_name = "^describe text test with .*$" },
      { index = 6, expected_name = "^describe text test with .* and \\(parenthesis\\)$" },
    }) do
      async.it("builds command with correct test name pattern " .. test_data.index, function()
        local adapter = require("neotest-jest")({ jestCommand = "jest" })
        -- Mock neotest process run to not run jest test discovery
        stub(require("neotest.lib").process, "run")

        local positions = adapter.discover_positions("./spec/parameterized.test.ts"):to_list()

        local tree = Tree.from_list(positions, function(pos)
          return pos.id
        end)

        local spec = adapter.build_spec({ tree = tree:children()[1]:children()[test_data.index] })

        assert.contains(spec.command, "--testNamePattern=" .. test_data.expected_name)
      end)
    end
  end)

  async.it("builds command for file test with extra arguments", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/basic.test.ts"
    local positions = adapter.discover_positions("./spec/basic.test.ts"):to_list()
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
  end)

  async.it("builds command for file test without extra arguments if not a list", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/basic.test.ts"
    local positions = adapter.discover_positions("./spec/basic.test.ts"):to_list()
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
  end)

  async.it("builds command for file test with jestCommand arg", function()
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/basic.test.ts"
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
  end)

  async.it("builds command with overridden jest arguments (string array)", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestOptions = { "--coverage", "--clearCache" },
    })

    local path = "./spec/basic.test.ts"
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
    assert._not.contains(command, "--json")
    assert._not.contains(command, "--config=./spec/jest.config.ts")
    assert._not.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--coverage")
    assert.contains(command, "--clearCache")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  end)

  async.it("builds command with overridden jest arguments (string array) and extra_args", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestOptions = { "--coverage", "--clearCache" },
    })

    local path = "./spec/basic.test.ts"
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
    assert._not.contains(command, "--json")
    assert._not.contains(command, "--config=./spec/jest.config.ts")
    assert._not.contains(command, "--testNamePattern=.*")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--coverage")
    assert.contains(command, "--clearCache")
    assert.contains(command, "--useStderr")
    assert.contains(command, "--updateSnapshot")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, path)
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  end)

  async.it("builds command with overridden jest arguments (function)", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestOptions = function(defaultOptions)
        local options = vim.tbl_filter(function(arg)
          return arg ~= "--no-coverage"
        end, defaultOptions)

        return vim.list_extend(options, { "--coverage", "--clearCache" })
      end,
    })

    local path = "./spec/basic.test.ts"
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
  end)

  async.it("builds command with overridden jest arguments (function) and extra_args", function()
    local adapter = require("neotest-jest")({
      jestCommand = "jest",
      jestOptions = function(defaultOptions)
        local options = vim.tbl_filter(function(arg)
          return arg ~= "--no-coverage"
        end, defaultOptions)

        return vim.list_extend(options, { "--coverage", "--clearCache" })
      end,
    })

    local path = "./spec/basic.test.ts"
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
  end)

  -- async.it("builds command with overridden jest arguments (function) and extra_args without duplicated options", function()
  --   local path = "./spec/basic.test.ts"
  --   local positions = adapter.discover_positions(path):to_list()
  --   local tree = Tree.from_list(positions, function(pos)
  --     return pos.id
  --   end)
  --   local spec = adapter.build_spec({
  --     tree = tree,
  --     jestOptions = function(defaultOptions)
  --       local options = vim.tbl_filter(function(arg)
  --         return arg ~= "--no-coverage"
  --       end, defaultOptions)
  --
  --       return vim.list_extend(options, { "--coverage", "--clearCache" })
  --     end,
  --     extra_args = { "--useStderr", "--updateSnapshot" },
  --   })
  --
  --   assert.is.truthy(spec)
  --   local command = spec.command
  --
  --   assert.is.truthy(command)
  --   assert.contains(command, "jest")
  --   assert._not.contains(command, "--no-coverage")
  --   assert.contains(command, "--testLocationInResults")
  --   assert.contains(command, "--verbose")
  --   assert.contains(command, "--json")
  --   assert.contains(command, "--config=./spec/jest.config.ts")
  --   assert.contains(command, "--testNamePattern=.*")
  --   assert.contains(command, "--forceExit")
  --   assert.contains(command, "--coverage")
  --   assert.contains(command, "--clearCache")
  --   assert.contains(command, "--useStderr")
  --   assert.contains(command, "--updateSnapshot")
  --   assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))
  --
  --   assert.are.same(spec.context.file, path)
  --   assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  -- end)

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
      jestOptions = jest_util.getJestOptions,
      env = { override = "override", adapter_override = true },
    })

    local path = "./spec/basic.test.ts"
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
  end)
end)

local adapter = require("neotest-jest")({ jestCommand = "jest" })
local async = require("nio").tests
local stub = require("luassert.stub")
local Tree = require("neotest.types").Tree
local util = require("neotest-jest.util")

require("neotest-jest-assertions")

describe("adapter.build_spec", function()
  async.it("builds command for file test", function()
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
    assert.contains(command, "--testNamePattern='.*'")
    assert.contains(command, "--forceExit")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, "./spec/basic.test.ts")
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  end)

  async.it("builds command for file test with jestCommand arg", function()
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
    assert.contains(command, "--testNamePattern='.*'")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, "./spec/basic.test.ts")
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  end)

  async.it("builds command for namespace", function()
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
    assert.contains(command, "--testNamePattern='^describe text'")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, "./spec/basic.test.ts")
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  end)

  async.it("builds command for nested namespace", function()
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
    assert.contains(command, "--testNamePattern='^outer middle inner'")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, "./spec/nestedDescribe.test.ts")
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))
  end)

  async.it("builds correct command for test name with ' ", function()
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
    assert.contains(command, "--testNamePattern='^outer middle inner this has a \\'$'")
    assert.contains(command, "spec\\/nestedDescribe.test.ts")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, "./spec/nestedDescribe.test.ts")
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
        -- Mock neotest process run to not run jest test discovery
        stub(require("neotest.lib").process, "run")

        local positions = adapter.discover_positions("./spec/parameterized.test.ts"):to_list()

        local tree = Tree.from_list(positions, function(pos)
          return pos.id
        end)

        local spec = adapter.build_spec({ tree = tree:children()[1]:children()[test_data.index] })

        assert.contains(spec.command, "--testNamePattern='" .. test_data.expected_name .. "'")
      end)
    end
  end)

  async.it("builds command with custom binary and config overrides", function()
    local binary_override = function()
      return "mybinaryoverride"
    end

    local config_override = function()
      return "./spec/jest.config.ts"
    end

    local _adapter = require("neotest-jest")({
      jestCommand = binary_override,
      jestConfigFile = config_override,
      env = { override = "override", adapter_override = true },
    })

    local path = "./spec/basic.test.ts"
    local positions = _adapter.discover_positions(path):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = _adapter.build_spec({ nil, { env = { spec_override = true } }, tree = tree })

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
    assert.contains(command, "--testNamePattern='.*'")
    assert.contains(command, util.escapeTestPattern(vim.fs.normalize(path)))

    assert.are.same(spec.context.file, "./spec/basic.test.ts")
    assert.is.truthy(vim.endswith(spec.context.results_path, ".json"))

    assert.is.same(
      spec.env,
      { override = "override", adapter_override = true, spec_override = true }
    )
  end)
end)

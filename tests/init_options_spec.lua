local async = require("nio").tests
local Tree = require("neotest.types").Tree
require("neotest-jest-assertions")

local binary_override = function()
  return "mybinaryoverride"
end

local options_override = function()
  return { "--coverage", "--json=true" }
end

local config_override = function()
  return "./spec/jest.config.ts"
end

describe("build_spec with override", function()
  async.it("builds command", function()
    local plugin = require("neotest-jest")({
      jestCommand = binary_override,
      jestOptions = options_override,
      jestConfigFile = config_override,
      env = { override = "override", adapter_override = true },
    })

    local positions = plugin.discover_positions("./spec/basic.test.ts"):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = plugin.build_spec({ nil, { env = { spec_override = true } }, tree = tree })

    assert.is.truthy(spec)

    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, binary_override())
    assert._not.contains(command, "--json")
    assert._not.contains(command, "--no-coverage")
    assert.contains(command, "--json=true")
    assert.contains(command, "--coverage")
    assert.contains(command, "--config=" .. config_override())
    assert.contains(command, "spec\\/basic.test.ts")
    assert.contains(command, "--forceExit")
    assert.contains(command, "--testLocationInResults")
    assert.contains(command, "--verbose")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)
    assert.is.same(
      spec.env,
      { override = "override", adapter_override = true, spec_override = true }
    )
  end)
end)

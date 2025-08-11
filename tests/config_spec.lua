local config = require("neotest-jest.config")
local notifications = require("neotest-jest.notifications")
local stub = require("luassert.stub")

describe("config", function()
  it("handles invalid configs", function()
    local invalid_configs = {
      {
        jestCommand = true,
      },
      {
        jestConfigFile = { a = 1 },
      },
      {
        env = 1,
      },
      {
        cwd = coroutine.create(function() end),
      },
      {
        strategyConfig = false,
      },
      {
        strategy_config = 1.45,
      },
      {
        jestTestDiscovery = { a = 1 },
      },
      {
        jest_test_discovery = "ok",
      },
    }

    stub(notifications, "error")

    for _, invalid_config in ipairs(invalid_configs) do
      local ok = config.configure(invalid_config)

      if ok then
        vim.print(invalid_config)
      end

      assert.is_false(ok)
    end

    ---@diagnostic disable-next-line: undefined-field
    notifications.error:revert()
  end)

  it("throws no errors for a valid config", function()
    local ok = config.configure(config._default_config())

    assert.is_true(ok)
  end)

  it("throws no errors for empty user config", function()
    ---@diagnostic disable-next-line: missing-fields
    assert.is_true(config.configure({}))
  end)

  it("throws no errors for no user config", function()
    assert.is_true(config.configure())
  end)
end)

local config = {}

local jest_util = require("neotest-jest.jest-util")
local notifications = require("neotest-jest.notifications")

---@alias neotest-jest.getEnvFunc fun(): table<string, unknown>
---@alias neotest-jest.getCwdFunc fun(): string?

---@class neotest-jest.Config
---@field jestCommand?         string | fun(): string
---@field jestConfigFile?      string | fun(): string
---@field env?                 table<string, unknown> | neotest-jest.getEnvFunc
---@field cwd?                 string | neotest-jest.getCwdFunc
---@field strategyConfig?      table<string, unknown> | fun(): table<string, unknown>
---@field strategy_config?     table<string, unknown> | fun(): table<string, unknown>
---@field jestTestDiscovery?   boolean
---@field jest_test_discovery? boolean

---@type neotest-jest.getEnvFunc
local function getEnv()
  return {}
end

---@type neotest-jest.getCwdFunc
local function getCwd()
  return nil
end

local function getDefaultStrategyConfig(strategy, command, cwd)
  local strategy_config = {
    dap = function()
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
    end,
  }

  if strategy_config[strategy] then
    return strategy_config[strategy]()
  end
end

---@type neotest-jest.Config
local default_config = {
  jestCommand = jest_util.getJestCommand,
  jestConfigFile = jest_util.getJestConfig,
  env = getEnv,
  cwd = getCwd,
  strategyConfig = getDefaultStrategyConfig,
  jestTestDiscovery = false,
}

---@type neotest-jest.Config
local _user_config = default_config

--- Used in testing
---@private
function config._default_config()
  return default_config
end

---@param object table<string, unknown>
---@param schema table<string, unknown>
---@return table
local function validate_schema(object, schema)
  local result = {}

  for key, validators in pairs(schema) do
    local valid, errors = pcall(vim.validate, key, object[key], validators, false)

    if not valid then
      table.insert(result, errors)
    end
  end

  for key, _ in pairs(object) do
    if not schema[key] then
      table.insert(result, ("Unknown config key '%s'"):format(key))
    end
  end

  return result
end
--- Validate a config
---@param _config neotest-jest.Config
---@return boolean
---@return any?
function config.validate(_config)
  local config_schema = {
    jestCommand = { "string", "function" },
    jestConfigFile = { "string", "function" },
    env = { "table", "function" },
    cwd = { "table", "function" },
    strategyConfig = { "table", "function" },
    strategy_config = { "table", "function" },
    jestTestDiscovery = "boolean",
    jest_test_discovery = "boolean",
  }

  local errors = validate_schema(_config, config_schema)

  return #errors == 0, errors
end

---@param option unknown?
local function resolve_config_option(option, default)
  if vim.is_callable(option) then
    return option
  elseif option then
    return function()
      return option
    end
  else
    return default
  end
end

---@param user_config? neotest-jest.Config
function config.configure(user_config)
  if user_config then
    _user_config.jestCommand =
        resolve_config_option(user_config.jestCommand, jest_util.getJestCommand)

    _user_config.jestConfigFile =
        resolve_config_option(user_config.jestConfigFile, jest_util.getJestConfig)

    _user_config.cwd = resolve_config_option(user_config.cwd, getCwd)

    _user_config.strategy_config =
        resolve_config_option(user_config.strategy_config, getDefaultStrategyConfig)

    _user_config.strategyConfig =
        resolve_config_option(user_config.strategyConfig, getDefaultStrategyConfig)

    _user_config.jest_test_discovery = user_config.jest_test_discovery and true or false
    _user_config.jestTestDiscovery = user_config.jestTestDiscovery and true or false

    if vim.is_callable(user_config.env) then
      _user_config.env = user_config.env
    elseif user_config.env then
      _user_config.env = function(specEnv)
        return vim.tbl_extend("force", user_config.env, specEnv)
      end
    end
  else
    _user_config = default_config
  end

  local ok, error = config.validate(_user_config)

  if not ok then
    notifications.error("Errors found in config: " .. table.concat(error, "\n"))
  end

  if _user_config.strategy_config then
    vim.deprecate("strategy_config", "strategyConfig", "soon", "neotest-jest", false)
  end

  if _user_config.jest_test_discovery then
    vim.deprecate("jest_test_discovery", "jestTestDiscovery", "soon", "neotest-jest", false)
  end

  return ok
end

setmetatable(config, {
  __index = function(_, key)
    return _user_config[key]
  end,
})

return config

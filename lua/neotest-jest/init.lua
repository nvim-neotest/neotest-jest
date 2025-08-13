---@diagnostic disable: undefined-field
local async = require("neotest.async")
local compat = require("neotest-jest.compat")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local util = require("neotest-jest.util")
local jest_util = require("neotest-jest.jest-util")
local parameterized_tests = require("neotest-jest.parameterized-tests")

---@class neotest-jest.JestArgumentContext
---@field config string?
---@field resultsPath string
---@field testNamePattern string

---@class neotest.JestOptions
---@field jestCommand? string | fun(): string
---@field jestArguments? string[] | fun(defaultArguments: string[], jestArgsContext: neotest-jest.JestArgumentContext): string[]
---@field jestConfigFile? string | fun(): string
---@field env? table<string, string> | fun(): table<string, string>
---@field cwd? string | fun(): string
---@field strategy_config? table<string, unknown> | fun(): table<string, unknown>

---@type neotest.Adapter
local adapter = { name = "neotest-jest" }

local rootPackageJson = vim.fn.getcwd() .. "/package.json"

---@return boolean
local function rootProjectHasJestDependency()
  local path = rootPackageJson

  local success, packageJsonContent = pcall(lib.files.read, path)
  if not success then
    print("cannot read package.json")
    return false
  end

  local parsedPackageJson = vim.json.decode(packageJsonContent)

  if parsedPackageJson["dependencies"] then
    for key, _ in pairs(parsedPackageJson["dependencies"]) do
      if key == "jest" then
        return true
      end
    end
  end

  if parsedPackageJson["devDependencies"] then
    for key, _ in pairs(parsedPackageJson["devDependencies"]) do
      if key == "jest" then
        return true
      end
    end
  end

  return false
end

---@param path string
---@return boolean
local function hasJestDependency(path)
  local rootPath = lib.files.match_root_pattern("package.json")(path)

  if not rootPath then
    return false
  end

  local success, packageJsonContent = pcall(lib.files.read, rootPath .. "/package.json")
  if not success then
    print("cannot read package.json")
    return false
  end

  local parsedPackageJson = vim.json.decode(packageJsonContent)

  if parsedPackageJson["dependencies"] then
    for key, _ in pairs(parsedPackageJson["dependencies"]) do
      if key == "jest" then
        return true
      end
    end
  end

  if parsedPackageJson["devDependencies"] then
    for key, _ in pairs(parsedPackageJson["devDependencies"]) do
      if key == "jest" then
        return true
      end
    end
  end

  if parsedPackageJson["scripts"] then
    for _, value in pairs(parsedPackageJson["scripts"]) do
      if value == "jest" then
        return true
      end
    end
  end

  return rootProjectHasJestDependency()
end

adapter.root = function(path)
  return lib.files.match_root_pattern("package.json")(path)
end

local getJestCommand = jest_util.getJestCommand
local getJestArguments = jest_util.getJestArguments
local getJestConfig = jest_util.getJestConfig

---@async
---@param file_path? string
---@return boolean
function adapter.is_test_file(file_path)
  if file_path == nil then
    return false
  end
  local is_test_file = false

  if file_path:match("__tests__") then
    is_test_file = true
  end

  for _, pattern in ipairs(util.getDefaultTestExtensionPatterns()) do
    if file_path:match(pattern) then
      is_test_file = true
      break
    end
  end

  return is_test_file and hasJestDependency(file_path)
end

function adapter.filter_dir(name)
  return name ~= "node_modules"
end

local function get_match_type(captured_nodes)
  if captured_nodes["test.name"] then
    return "test"
  end
  if captured_nodes["namespace.name"] then
    return "namespace"
  end
end

-- Enrich `it.each` tests with metadata about TS node position
function adapter.build_position(file_path, source, captured_nodes)
  local match_type = get_match_type(captured_nodes)

  if not match_type then
    return
  end

  ---@type string
  local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
  local definition = captured_nodes[match_type .. ".definition"]

  return {
    type = match_type,
    path = file_path,
    name = name,
    range = { definition:range() },
    is_parameterized = captured_nodes["each_property"] and true or false,
  }
end

---@async
---@return neotest.Tree | nil
function adapter.discover_positions(path)
  local query = [[
    ; -- Namespaces --
    ; Matches: `describe('context', () => {})`
    ((call_expression
      function: (identifier) @func_name (#eq? @func_name "describe")
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe('context', function() {})`
    ((call_expression
      function: (identifier) @func_name (#eq? @func_name "describe")
      arguments: (arguments (string (string_fragment) @namespace.name) (function_expression))
    )) @namespace.definition
    ; Matches: `describe.only('context', () => {})`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "describe")
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe.only('context', function() {})`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "describe")
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (function_expression))
    )) @namespace.definition
    ; Matches: `describe.each(['data'])('context', () => {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "describe")
        )
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe.each(['data'])('context', function() {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "describe")
        )
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (function_expression))
    )) @namespace.definition

    ; -- Tests --
    ; Matches: `test('test') / it('test')`
    ((call_expression
      function: (identifier) @func_name (#any-of? @func_name "it" "test")
      arguments: (arguments (string (string_fragment) @test.name) [(arrow_function) (function_expression)])
    )) @test.definition
    ; Matches: `test.only('test') / it.only('test')`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "test" "it")
      )
      arguments: (arguments (string (string_fragment) @test.name) [(arrow_function) (function_expression)])
    )) @test.definition
    ; Matches: `test.each(['data'])('test') / it.each(['data'])('test')`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "it" "test")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments (string (string_fragment) @test.name) [(arrow_function) (function_expression)])
    )) @test.definition
  ]]

  local positions = lib.treesitter.parse_positions(path, query, {
    nested_tests = false,
    build_position = 'require("neotest-jest").build_position',
  })

  local parameterized_tests_positions =
    parameterized_tests.get_parameterized_tests_positions(positions)

  if adapter.jest_test_discovery and #parameterized_tests_positions > 0 then
    parameterized_tests.enrich_positions_with_parameterized_tests(
      positions:data().path,
      parameterized_tests_positions
    )
  end

  return positions
end

local function get_default_strategy_config(strategy, command, cwd)
  local config = {
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
  if config[strategy] then
    return config[strategy]()
  end
end

local function getEnv(specEnv)
  return specEnv
end

---@param path string
---@return string|nil
local function getCwd(path)
  return nil
end

local function getStrategyConfig(default_strategy_config, args)
  return default_strategy_config
end

local function cleanAnsi(s)
  return s:gsub("\x1b%[%d+;%d+;%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+m", "")
    :gsub("\x1b%[%d+m", "")
end

local function findErrorPosition(file, errStr)
  -- Look for: /path/to/file.js:123:987
  local regexp = file:gsub("([^%w])", "%%%1") .. "%:(%d+)%:(%d+)"
  local _, _, errLine, errColumn = errStr:find(regexp)

  return errLine, errColumn
end

local function parsed_json_to_results(data, output_file, consoleOut)
  local tests = {}

  for _, testResult in pairs(data.testResults) do
    local testFn = testResult.name
    for _, assertionResult in pairs(testResult.assertionResults) do
      local status, name = assertionResult.status, assertionResult.title

      if name == nil then
        logger.error("Failed to find parsed test result ", assertionResult)
        return {}
      end

      local keyid = testFn

      for _, value in ipairs(assertionResult.ancestorTitles) do
        keyid = keyid .. "::" .. value
      end

      keyid = keyid .. "::" .. name

      if status == "pending" then
        status = "skipped"
      end

      tests[keyid] = {
        status = status,
        short = name .. ": " .. status,
        output = consoleOut,
        location = assertionResult.location,
      }

      if not vim.tbl_isempty(assertionResult.failureMessages) then
        local errors = {}

        for i, failMessage in ipairs(assertionResult.failureMessages) do
          local msg = cleanAnsi(failMessage)
          local errorLine, errorColumn = findErrorPosition(testFn, msg)

          errors[i] = {
            line = (errorLine or assertionResult.location.line) - 1,
            column = (errorColumn or 1) - 1,
            message = msg,
          }

          tests[keyid].short = tests[keyid].short .. "\n" .. msg
        end

        tests[keyid].errors = errors
      end
    end
  end

  return tests
end

---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function adapter.build_spec(args)
  ---@type string
  local results_path = async.fn.tempname() .. ".json"
  local tree = args.tree

  if not tree then
    return
  end

  local pos = args.tree:data()
  local testNamePattern = ".*"

  if pos.type == "test" or pos.type == "namespace" then
    -- pos.id in form "path/to/file::Describe text::test text"
    local testName = pos.id:sub(pos.id:find("::") + 2)
    testName, _ = testName:gsub("::", " ")
    testNamePattern = util.escapeTestPattern(testName)
    testNamePattern = pos.is_parameterized
        and parameterized_tests.replaceTestParametersWithRegex(testNamePattern)
      or testNamePattern
    testNamePattern = "^" .. testNamePattern
    if pos.type == "test" then
      testNamePattern = testNamePattern .. "$"
    end
  end

  local binary = args.jestCommand or getJestCommand(pos.path)
  local config = getJestConfig(pos.path) or "jest.config.js"
  local command = vim.split(binary, "%s+")

  local jestArgsContext = {
    config = config,
    resultsPath = results_path,
    testNamePattern = testNamePattern,
  }

  local options =
    getJestArguments(jest_util.getJestDefaultArguments(jestArgsContext), jestArgsContext)

  vim.list_extend(command, options)

  -- We need to pass a few options regardless of any user specific options:
  if compat.tbl_islist(args.extra_args) then
    vim.list_extend(command, args.extra_args)
  end

  vim.list_extend(command, {
    "--forceExit", -- Ensure jest and thus the adapter does not hang
    "--testLocationInResults", -- Ensure jest outputs test locations
    util.escapeTestPattern(vim.fs.normalize(pos.path)),
  })

  local cwd = getCwd(pos.path)

  -- creating empty file for streaming results
  lib.files.write(results_path, "")
  local stream_data, stop_stream = util.stream(results_path)

  return {
    command = command,
    cwd = cwd,
    context = {
      results_path = results_path,
      file = pos.path,
      stop_stream = stop_stream,
    },
    stream = function()
      return function()
        local new_results = stream_data()
        local ok, parsed = pcall(vim.json.decode, new_results, { luanil = { object = true } })

        if not ok or not parsed.testResults then
          return {}
        end

        return parsed_json_to_results(parsed, results_path, nil)
      end
    end,
    strategy = getStrategyConfig(
      get_default_strategy_config(args.strategy, command, cwd) or {},
      args
    ),
    env = getEnv(args[2] and args[2].env or {}),
  }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function adapter.results(spec, result, tree)
  spec.context.stop_stream()

  local output_file = spec.context.results_path

  local success, data = pcall(lib.files.read, output_file)

  if not success then
    logger.error("No test output file found ", output_file)
    return {}
  end

  local ok, parsed = pcall(vim.json.decode, data, { luanil = { object = true } })

  if not ok then
    logger.error("Failed to parse test output json ", output_file)
    return {}
  end

  local results = parsed_json_to_results(parsed, output_file, result.output)

  return results
end

---@generic T
---@param value T | fun(any): T
---@param default fun(any): T
---@return fun(any): T
local function resolve_config_option(value, default)
  if util.is_callable(value) then
    return value
  elseif value then
    return function()
      return value
    end
  end

  return default
end

setmetatable(adapter, {
  ---@param opts neotest.JestOptions
  __call = function(_, opts)
    getJestCommand = resolve_config_option(opts.jestCommand, getJestCommand)
    getJestArguments = resolve_config_option(opts.jestArguments, getJestArguments)
    getJestConfig = resolve_config_option(opts.jestConfigFile, getJestConfig)
    getCwd = resolve_config_option(opts.cwd, getCwd)
    getStrategyConfig = resolve_config_option(opts.strategy_config, getStrategyConfig)

    if util.is_callable(opts.env) then
      getEnv = opts.env
    elseif opts.env then
      getEnv = function(specEnv)
        return vim.tbl_extend("force", opts.env, specEnv)
      end
    end

    if opts.jest_test_discovery then
      adapter.jest_test_discovery = true
    end

    return adapter
  end,
})

return adapter

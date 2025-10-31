---@diagnostic disable: undefined-field
local async = require("neotest.async")
local compat = require("neotest-jest.compat")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local util = require("neotest-jest.util")
local jest_util = require("neotest-jest.jest-util")
local parameterized_tests = require("neotest-jest.parameterized-tests")
local types = require("neotest.types")

local ResultStatus = types.ResultStatus

---@class neotest-jest.JestArgumentContext
---@field config string?
---@field resultsPath string
---@field testNamePattern string

---@class neotest.JestOptions
---@field jestCommand? string | fun(): string
---@field jestArguments? fun(defaultArguments: string[], jestArgsContext: neotest-jest.JestArgumentContext): string[]
---@field jestConfigFile? string | fun(file_path: string): string
---@field env? table<string, string> | fun(): table<string, string>
---@field cwd? string | fun(): string
---@field strategy_config? table<string, unknown> | fun(): table<string, unknown>
---@field isTestFile async fun(file_path: string?): boolean

---@type neotest.Adapter
local adapter = { name = "neotest-jest" }

adapter.root = function(path)
  return lib.files.match_root_pattern("package.json")(path)
end

local getJestCommand = jest_util.getJestCommand
local getJestArguments = jest_util.getJestArguments
local getJestConfig = jest_util.getJestConfig
local isTestFile = jest_util.defaultIsTestFile

---@async
---@param file_path? string
---@return boolean
function adapter.is_test_file(file_path)
  return isTestFile(file_path)
end

function adapter.filter_dir(name)
  return name ~= "node_modules"
end

---@param captured_nodes TSNode[]
---@return ("test" | "namespace")?
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

  ---@type TSNode
  local node = captured_nodes[match_type .. ".name"]
  local name = vim.treesitter.get_node_text(node, source)
  local definition = captured_nodes[match_type .. ".definition"]
  local type = node:type()
  local nonStringNode = false

  if type == "string" then
    -- If the node is a string then strip the quotes from the name by getting
    -- it's first named child (string_fragment). This works for single-, double-,
    -- and literal quotes and is necessary since we match anything in the queries
    -- used in discover_positions
    local content = node:named_child(0)

    if content then
      name = vim.treesitter.get_node_text(content, source)
    end
  elseif type == "template_string" then
    -- If the node is a template string then concatenate its named children
    -- which is essentially the inner part of the backticks thus stripping
    -- backticks. This is necessary since we match anything in the queries used
    -- in discover_positions
    local new_name = {}

    for _, named_child in ipairs(node:named_children()) do
      table.insert(new_name, vim.treesitter.get_node_text(named_child, source))
    end

    name = table.concat(new_name, "")
  else
    nonStringNode = true
  end

  return {
    type = match_type,
    path = file_path,
    name = name,
    range = { definition:range() },
    -- Record the position of the line where the string name occurs
    test_name_range = match_type == "test" and { node:range() } or nil,
    is_parameterized = (captured_nodes["each_property"] or nonStringNode) and true or false,
  }
end

---@async
---@return neotest.Tree | nil
function adapter.discover_positions(path)
  -- NOTE: Combining queries with a second argument that can be either
  -- arrow_function, function_expression, or call_expression seems to
  -- change the order of the matches so that namespaces or listed after
  -- tests. When neotest builds the tree tests are not properly nested
  -- under their namespace. This might be because the range of a combined
  -- query can end later that a test, changing the order that matches are
  -- iterated
  local query = [[
    ; ##############
    ; # Namespaces #
    ; ##############

    ; Matches: `describe('context', () => {})`
    ((call_expression
        function: (identifier) @func_name (#eq? @func_name "describe")
          arguments: (arguments ((_) @namespace.name) (arrow_function))
    )) @namespace.definition

    ; Matches: `describe('context', function() {})`
    ((call_expression
        function: (identifier) @func_name (#eq? @func_name "describe")
          arguments: (arguments ((_) @namespace.name) (function_expression))
    )) @namespace.definition

    ; Matches: `describe('context', wrapper())`
    ((call_expression
        function: (identifier) @func_name (#eq? @func_name "describe")
          arguments: (arguments ((_) @namespace.name) (call_expression))
    )) @namespace.definition

    ; Matches: `describe.only('context', () => {})`
    ((call_expression
        function: (member_expression
            object: (identifier) @func_name (#eq? @func_name "describe")
        )
        arguments: (arguments ((_) @namespace.name) (arrow_function))
    )) @namespace.definition

    ; Matches: `describe.only('context', function() {})`
    ((call_expression
        function: (member_expression
            object: (identifier) @func_name (#eq? @func_name "describe")
        )
        arguments: (arguments ((_) @namespace.name) (function_expression))
    )) @namespace.definition

    ; Matches: `describe.only('context', wrapper())`
    ((call_expression
        function: (member_expression
            object: (identifier) @func_name (#eq? @func_name "describe")
        )
        arguments: (arguments ((_) @namespace.name) (call_expression))
    )) @namespace.definition

    ; Matches: `describe.each(['data'])('context', () => {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#eq? @func_name "describe")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments ((_) @namespace.name) (arrow_function))
    )) @namespace.definition

    ; Matches: `describe.each(['data'])('context', function() {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#eq? @func_name "describe")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments ((_) @namespace.name) (function_expression))
    )) @namespace.definition

    ; Matches: `describe.each(['data'])('context', wrapper())`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#eq? @func_name "describe")
        )
      )
      arguments: (arguments ((_) @namespace.name) (call_expression))
    )) @namespace.definition

    ; #########
    ; # Tests #
    ; #########

    ; Matches: `it('test', () => {}) / test('test', () => {})`
    ((call_expression
      function: (identifier) @func_name (#any-of? @func_name "it" "test")
        arguments: (arguments ((_) @test.name) (arrow_function))
    )) @test.definition

    ; Matches: `it('test', function() {}) / test('test', function() {})`
    ((call_expression
      function: (identifier) @func_name (#any-of? @func_name "it" "test")
        arguments: (arguments ((_) @test.name) (function_expression))
    )) @test.definition

    ; Matches: `it('test', wrapper()) / test('test', wrapper())`
    ((call_expression
      function: (identifier) @func_name (#any-of? @func_name "it" "test")
        arguments: (arguments ((_) @test.name) (call_expression))
    )) @test.definition

    ; Matches: `test.only('test', () => {}) / it.only('test', () => {})`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "test" "it")
      )
      arguments: (arguments ((_) @test.name) (arrow_function))
    )) @test.definition

    ; Matches: `test.only('test', function() {}) / it.only('test', function() {})`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "test" "it")
      )
      arguments: (arguments ((_) @test.name) (function_expression))
    )) @test.definition

    ; Matches: `test.only('test', wrapper()) / it.only('test', wrapper())`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "test" "it")
      )
      arguments: (arguments ((_) @test.name) (call_expression))
    )) @test.definition

    ; Matches: `test.each(['data'])('test', () => {}) / it.each(['data'])('test', () => {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "it" "test")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments ((_) @test.name) (arrow_function))
    )) @test.definition

    ; Matches: `test.each(['data'])('test', function() {}) / it.each(['data'])('test', function() {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "it" "test")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments ((_) @test.name) (function_expression))
    )) @test.definition

    ; Matches: `test.each(['data'])('test', wrapper()) / it.each(['data'])('test', wrapper())`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "it" "test")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments ((_) @test.name) (call_expression))
    )) @test.definition
  ]]

  ---@diagnostic disable-next-line: missing-fields
  local positions = lib.treesitter.parse_positions(path, query, {
    nested_tests = false,
    ---@diagnostic disable-next-line: assign-type-mismatch
    build_position = 'require("neotest-jest").build_position',
  })

  if adapter.jest_test_discovery then
    local parameterized_tests_positions =
      parameterized_tests.getParameterizedTestsPositions(positions)

    if #parameterized_tests_positions > 0 then
      parameterized_tests.enrichPositionsWithParameterizedTests(
        positions:data().path,
        parameterized_tests_positions
      )
    end
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
  local tree = args.tree

  if not tree then
    return
  end

  local pos = tree:data()
  local testNamePattern = ".*"

  if pos.type == types.PositionType.test or pos.type == types.PositionType.namespace then
    local sourceLevelTest = parameterized_tests.getParametricTestToSourceLevelTest(pos.path, pos.id)
    local testName = sourceLevelTest or pos.id

    testName, _ = testName:sub(pos.id:find("::") + 2):gsub("::", " ")
    testNamePattern = util.escapeTestPattern(testName)

    -- If the position or any of its enclosing blocks are parameterized, replace any
    -- test parameters with a match-all regex so we can run the test
    if parameterized_tests.isPositionParameterized(tree, pos) then
      testNamePattern = parameterized_tests.replaceTestParametersWithRegex(testNamePattern)
    end

    testNamePattern = "^" .. testNamePattern

    -- Jest's 'testNamePattern' matches against the full test name so if we added
    -- '$' to a namespace position it would never match any tests
    if pos.type == types.PositionType.test then
      testNamePattern = testNamePattern .. "$"
    end
  end

  local binary = args.jestCommand or getJestCommand(pos.path)
  local config = getJestConfig(pos.path) or "jest.config.js"
  local command = vim.split(binary, "%s+")

  ---@type string
  local results_path = async.fn.tempname() .. ".json"

  local jestArgsContext = {
    config = config,
    resultsPath = results_path,
    testNamePattern = testNamePattern,
  }

  local options =
    getJestArguments(jest_util.getJestDefaultArguments(jestArgsContext), jestArgsContext)

  if compat.tbl_islist(options) then
    vim.list_extend(command, options)
  else
    vim.notify(
      ("Jest arguments must be a list, got '%s'"):format(type(options)),
      vim.log.levels.ERROR
    )

    -- Add the default arugments to allow neotest to run
    vim.list_extend(command, jest_util.getJestDefaultArguments(jestArgsContext))
  end

  if compat.tbl_islist(args.extra_args) then
    vim.list_extend(command, args.extra_args)
  elseif args.extra_args then
    vim.notify(
      ("Extra arguments must be a list, got '%s'"):format(type(options)),
      vim.log.levels.ERROR
    )
  end

  table.insert(command, util.escapeTestPattern(vim.fs.normalize(pos.path)))

  local cwd = getCwd(pos.path)

  -- Creating empty file for streaming results
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
  local pos = tree:data()

  -- FIX: Generate results for source-level parametrized namespaces
  if
    adapter.jest_test_discovery == true and parameterized_tests.isPositionParameterized(tree, pos)
  then
    local status

    -- Aggregate result status and create a result for the target
    -- (source-level-only) position which was not part of the json
    -- results
    -- TODO: Maybe just do this in parsed_json_to_results?
    for _, test_result in pairs(results) do
      if test_result.status == ResultStatus.failed then
        status = test_result.status
        break
      elseif test_result.status == ResultStatus.passed then
        status = test_result.status
      elseif test_result.status == ResultStatus.skipped then
        if not status or status == ResultStatus.skipped then
          status = ResultStatus.skipped
        end
      end
    end

    -- If the position has a source position id (meaning it is
    -- a parametric test) generate a result for it so it shows
    -- up for the original source-level position
    if pos.source_pos_id then
      results[pos.source_pos_id] = {
        status = status,
        short = ("%s: %s"):format(pos.name, status),
        output = result.output,
      }
    end

    results[pos.id] = {
      status = status,
      short = ("%s: %s"):format(pos.name, status),
      output = result.output,
    }
  end

  return results
end

---@generic T
---@param value T | fun(any): T
---@param default fun(any): T
---@param reject_value boolean?
---@return fun(any): T
local function resolve_config_option(value, default, reject_value)
  if util.is_callable(value) then
    return value
  elseif value and not reject_value then
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
    getJestArguments = resolve_config_option(opts.jestArguments, getJestArguments, true)
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

    if util.is_callable(opts.isTestFile) then
      isTestFile = opts.isTestFile
    end

    return adapter
  end,
})

return adapter

---@diagnostic disable: undefined-field
local lib = require "neotest.lib"
local logger = require "neotest.logging"

---@type neotest.Adapter
local adapter = { name = "neotest-jest" }

adapter.root = lib.files.match_root_pattern "package.json"

function adapter.is_test_file(file_path)
  if file_path == nil then
    return false
  end
  if string.match(file_path, "__tests__") then
    return true
  end
  for _, x in ipairs { "spec", "test" } do
    for _, ext in ipairs { "js", "jsx", "coffee", "ts", "tsx" } do
      if string.match(file_path, x .. "%." .. ext .. "$") then
        return true
      end
    end
  end
  return false
end

---@async
---@return neotest.Tree | nil
function adapter.discover_positions(path)
  local query = [[
  ((call_expression
      function: (identifier) @func_name (#match? @func_name "^describe$")
      arguments: (arguments (_) @namespace.name (arrow_function))
  )) @namespace.definition


  ((call_expression
      function: (identifier) @func_name (#match? @func_name "^it$")
      arguments: (arguments (_) @test.name (arrow_function))
  ) ) @test.definition
    ]]
  return lib.treesitter.parse_positions(path, query, { nested_tests = true })
end

---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function adapter.build_spec(args)
  --logger.debug("buildspec", args, "args")
  --lib.
  local results_path = vim.fn.tempname() .. ".json"
  local tree = args.tree
  if not tree then
    return
  end
  local pos = args.tree:data()
  -- if pos.type == "dir" then
  --   return
  --roots
  -- A list of paths to directories that Jest should use to search for files in.
  -- end
  local testNamePattern = ".*"
  if pos.type == "test" then
    testNamePattern = pos.name
  end

  local binary = "jest"
  if vim.fn.filereadable "node_modules/.bin/jest" then
    binary = "node_modules/.bin/jest"
  end

  local command = vim.tbl_flatten {
    binary,
    "--no-coverage",
    "--testLocationInResults",
    "--verbose",
    "--json",
    "--outputFile=" .. results_path,
    "--testNamePattern=" .. testNamePattern,
    "--runTestsByPath",
    pos.path,
  }
  return {
    command = command,
    context = {
      results_path = results_path,
      file = pos.path,
    },
  }
end

local function cleanAnsi(s)
  return s
      :gsub("\x1b%[%d+;%d+;%d+;%d+;%d+m", "")
      :gsub("\x1b%[%d+;%d+;%d+;%d+m", "")
      :gsub("\x1b%[%d+;%d+;%d+m", "")
      :gsub("\x1b%[%d+;%d+m", "")
      :gsub("\x1b%[%d+m", "")
end

local function findErrorLine(line, errStr)
  local _, _, errLine = string.find(errStr, "(%d+)%:%d+")
  if errLine then
    return errLine - 1
  end
  return line
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return neotest.Result[]
function adapter.results(spec, _, tree)
  vim.pretty_print(spec)
  local output_file = spec.context.results_path
  local success, data = pcall(lib.files.read, output_file)
  if not success then
    vim.schedule(function() -- FIXME: Report global errors correctly
      vim.notify "no file"
    end)
    return {}
  end
  local ok, parsed = pcall(vim.json.decode, data, { luanil = { object = true } })
  if not ok then
    vim.schedule(function() -- FIXME: Report global errors correctly
      vim.notify("Failed to parse json: " .. parsed)
    end)
    return {}
  end

  local tests = {}

  local testFn = parsed.testResults[1].name
  for _, result in pairs(parsed.testResults[1].assertionResults) do
    vim.pretty_print(result)
    local status, name = result.status, result.title
    if name == nil then
      vim.schedule(function() -- FIXME: Report global errors correctly
        vim.notify("Failed to get test result: " .. parsed)
      end)
      return {}
    end
    local keyid = testFn
    for _, value in ipairs(result.ancestorTitles) do
      keyid = keyid .. "::" .. '"' .. value .. '"'
    end
    keyid = keyid .. "::" .. '"' .. name .. '"'
    tests[keyid] = {
      status = status,
      short = name .. ": " .. status,
      output = output_file,
      location = result.location,
    }
    if result.failureMessages then
      local errors = {}
      for i, failMessage in ipairs(result.failureMessages) do
        local msg = cleanAnsi(failMessage)
        errors[i] = {
          line = findErrorLine(result.location.line - 1, msg),
          message = msg,
        }
        tests[keyid].short = tests[keyid].short .. "\n" .. msg
      end
      tests[keyid].errors = errors
    end
  end

  local results = {}
  for _, value in tree:iter() do
    local test_output = tests[value.id]
    if test_output == nil then
      if value.type ~= "file" or value.type ~= "namespace" then
        vim.notify("unable to find test result: " .. value.id)
        vim.pretty_print(value)
        return results
      end
    end
    results[value.id] = test_output
  end
  vim.pretty_print(results)
  return results
end

setmetatable(adapter, {
  __call = function()
    return adapter
  end,
})

return adapter

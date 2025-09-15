local lib = require("neotest.lib")
local jest_util = require("neotest-jest.jest-util")
local types = require("neotest.types")

local M = {}

-- Traverses through whole Tree and returns all parameterized tests positions.
-- All parameterized test positions should have `is_parameterized` property on it.
-- @param positions neotest.Tree
-- @return neotest.Tree[]
function M.get_parameterized_tests_positions(positions)
  local parameterized_tests_positions = {}

  for _, value in positions:iter_nodes() do
    local data = value:data()

    -- FIX: This does not take parameterized namespaces into account
    if data.type == types.PositionType.test and data.is_parameterized == true then
      table.insert(parameterized_tests_positions, value)
    end
  end

  return parameterized_tests_positions
end

-- Synchronously runs `jest` in `file_path` directory skipping all tests and returns `jest` output.
-- Output have all of the test names inside it. It skips all tests by adding
-- extra `--testPathPattern` parameter to jest command with placeholder string that should never exist.
-- @param file_path string - path to file to search for tests
-- @return table - parsed jest test results
local function run_jest_test_discovery(file_path)
  local binary = jest_util.getJestCommand(file_path)
  local command = vim.split(binary, "%s+")

  vim.list_extend(command, {
    "--no-coverage",
    "--testLocationInResults",
    "--verbose",
    "--json",
    file_path,
    "-t",
    "@______________PLACEHOLDER______________@",
  })

  -- TODO: Switch to nvim-nio
  local result = { lib.process.run(command, { stdout = true, stderr = false }) }

  if not result[2] then
    return nil
  end

  local jest_json_string = result[2].stdout

  if not jest_json_string or #jest_json_string == 0 then
    return nil
  end

  local ok, json = pcall(vim.json.decode, jest_json_string, { luanil = { object = true } })

  if not ok then
    return nil
  end

  return json
end

-- Searches through whole `jest` command output and returns array of all tests at given `position`.
---@param jest_output table
---@return table<integer, { pos_id: string, name: string }[]>
local function getTestsByPosition(jest_output)
  local tests_by_position = {}

  for _, testResult in pairs(jest_output.testResults) do
    local testFile = testResult.name

    for _, assertionResult in pairs(testResult.assertionResults) do
      local line, name = assertionResult.location.line - 1, assertionResult.title
      local pos_id = jest_util.getNeotestPositionIdFromTestResult(testFile, assertionResult)

      if not tests_by_position[line] then
        tests_by_position[line] = {}
      end

      table.insert(tests_by_position[line], { pos_id = pos_id, name = name })
    end
  end

  return tests_by_position
end

-- Add new tree nodes for parameterized tests to the existing neotest tree
---@param file_path string
---@param parsed_parameterized_tests_positions neotest.Tree[]
function M.enrich_positions_with_parameterized_tests(
    file_path,
    parsed_parameterized_tests_positions
)
  -- Get all runtime test information for path
  local jest_test_discovery_output = run_jest_test_discovery(file_path)

  if jest_test_discovery_output == nil then
    return
  end

  local tests_by_position = getTestsByPosition(jest_test_discovery_output)

  -- For each parameterized test, find all tests that were in the same position
  -- as it and add new range-less (range = nil) children to the tree
  for _, tree in pairs(parsed_parameterized_tests_positions) do
    local pos = tree:data()
    local parameterized_test_results_for_position = tests_by_position[pos.range[1]] or {}

    -- TODO: Can we generate children for namespaces here too?
    for _, test_result in ipairs(parameterized_test_results_for_position) do
      -- WARNING: The following code relies on neotest internals
      local new_data = {
        id = test_result.pos_id,
        name = test_result.name,
        path = pos.path,
        range = nil,
      }

      ---@diagnostic disable-next-line: invisible
      local new_tree = types.Tree:new(new_data, {}, tree._key, nil, nil)

      ---@diagnostic disable-next-line: invisible
      tree:add_child(new_data.id, new_tree)
    end
  end
end

local JEST_PARAMETER_TYPES = {
  "%%p",
  "%%s",
  "%%d",
  "%%i",
  "%%f",
  "%%j",
  "%%o",
  "%%#",
  "%%%%",
}

---@param tree neotest.Tree
---@param pos neotest.Position
---@return boolean
function M.isPositionParameterized(tree, pos)
  ---@type neotest.Tree?
  local current_tree = tree

  -- Look at each parent of the current position to see if it is parameterized
  -- (using `.each`). This is necessary if a test itself is not parameterized
  -- but one of its encloding describe blocks are
  while pos do
    ---@diagnostic disable-next-line: undefined-field
    if pos.is_parameterized then
      return true
    end

    ---@diagnostic disable-next-line: need-check-nil
    current_tree = current_tree:parent()

    if not current_tree then
      break
    end

    pos = current_tree:data()
  end

  return false
end

-- Replaces all of the jest parameters (named and unnamed) with `.*` regex
-- pattern. It allows to run all of the parameterized tests in a single run.
-- Idea inpired by Webstorm jest plugin.
--
---@param test_name string - test name with escaped characters
---@return string
function M.replaceTestParametersWithRegex(test_name)
  -- Replace named parameters: named characters can be single word (like
  -- $parameterName) or field access words (like $parameterName.fieldName)
  local result = test_name:gsub("\\$[%a%.]+", ".*")

  for _, parameter in ipairs(JEST_PARAMETER_TYPES) do
    result = result:gsub(parameter, ".*")
  end

  return result
end

return M

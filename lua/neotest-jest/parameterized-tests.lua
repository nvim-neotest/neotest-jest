local lib = require("neotest.lib")
local util = require("neotest-jest.util")
local jest_util = require("modified-plugins.neotest-jest.lua.neotest-jest.jest-util")

local M = {}

-- Traverses through whole Tree and returns all parameterized tests positions.
-- All parameterized test positions should have `is_parameterized` property on it.
-- @param positions neotest.Tree
-- @return neotest.Tree[]
function M.get_parameterized_tests_positions(positions)
  local parameterized_tests_positions = {}

  for _, value in positions:iter_nodes() do
    local data = value:data()

    if data.type == "test" and data.is_parameterized == true then
      parameterized_tests_positions[#parameterized_tests_positions + 1] = value
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
  local config = jest_util.getJestConfig(file_path) or "jest.config.js"
  local command = vim.split(binary, "%s+")
  if util.path.exists(config) then
    -- only use config if available
    table.insert(command, "--config=" .. config)
  end

  vim.list_extend(command, {
    "--no-coverage",
    "--testLocationInResults",
    "--verbose",
    "--json",
    file_path,
    "-t",
    "@______________PLACEHOLDER______________@",
  })

  local result = { lib.process.run(command, { stdout = true }) }

  if not result[2] then
    return nil
  end

  local jest_json_string = result[2].stdout

  if not jest_json_string or #jest_json_string == 0 then
    return nil
  end

  return vim.json.decode(jest_json_string, { luanil = { object = true } })
end

-- Searches through whole `jest` command output and returns array of all tests at given `position`.
-- @param jest_output table
-- @param position number[]
-- @return { keyid: string, name: string }[]
local function get_tests_ids_at_position(jest_output, position)
  local test_ids_at_position = {}
  for _, testResult in pairs(jest_output.testResults) do
    local testFile = testResult.name

    for _, assertionResult in pairs(testResult.assertionResults) do
      local location, name = assertionResult.location, assertionResult.title

      if position[1] <= location.line - 1 and position[3] >= location.line - 1 then
        local keyid = jest_util.get_test_full_id_from_test_result(testFile, assertionResult)

        test_ids_at_position[#test_ids_at_position + 1] = { keyid = keyid, name = name }
      end
    end
  end

  return test_ids_at_position
end

-- First runs `jest` in `file_path` to get all of the tests in the file. Then it takes all of
-- the parameterized tests and finds tests that were in the same position as parameterized test
-- and adds new tests (with range=nil) to the parameterized test.
-- @param file_path string
-- @param each_tests_positions neotest.Tree[]
function M.enrich_positions_with_parameterized_tests(file_path, each_tests_positions)
  local jest_test_discovery_output = run_jest_test_discovery(file_path)

  if jest_test_discovery_output == nil then
    return
  end

  for _, value in pairs(each_tests_positions) do
    local data = value:data()

    local each_test_results = get_tests_ids_at_position(jest_test_discovery_output, data.range)

    for _, each_test_result in ipairs(each_test_results) do
      local new_data = {
        id = each_test_result.keyid,
        name = each_test_result.name,
        path = data.path,
      }
      new_data.range = nil

      local new_pos = value:new(new_data, {}, value._key, {}, {})
      value:add_child(new_data.id, new_pos)
    end
  end
end

return M

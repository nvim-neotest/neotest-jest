local lib = require("neotest.lib")
local util = require("neotest-jest.util")
local jest_util = require("modified-plugins.neotest-jest.lua.neotest-jest.jest-util")

local M = {}

function M.get_parameterized_tests_positions(positions)
  local parameterized_tests_positions = {}

  for _, value in positions:iter_nodes() do
    local data = value:data()

    if data.type == "test" and data.each_test_meta then
      parameterized_tests_positions[#parameterized_tests_positions + 1] = value
    end
  end

  return parameterized_tests_positions
end

-- Runs `jest` in `positins` directory skipping all tests. It skips all tests by adding
-- extra `--testPathPattern` parameter to jest command with placeholder string that should never exist.
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

function M.enrich_positions_with_parameterized_tests(file_path, each_tests_positions)
  local jest_test_discovery_output = run_jest_test_discovery(file_path)

  if jest_test_discovery_output == nil then
    return
  end

  for _, value in pairs(each_tests_positions) do
    local data = value:data()

    local each_test_results =
      get_tests_ids_at_position(jest_test_discovery_output, data.each_test_meta.jest_test_position)

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

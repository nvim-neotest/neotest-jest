local lib = require("neotest.lib")
local jest_util = require("neotest-jest.jest-util")
local types = require("neotest.types")
local logger = require("neotest.logging")

local M = {}

---@class neotest-jest.RuntimeTestInfo
---@field pos_id           string
---@field name             string
---@field namespace_pos_id string
---@field namespace_name   string

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

local JEST_NAMED_PARAMETER_REGEX = "\\$[%a%.]+"

---@param pos neotest.Position
---@return boolean
local function isTestOrNamespace(pos)
  return pos.type == types.PositionType.test or pos.type == types.PositionType.namespace
end

-- Traverses through whole Tree and returns all parameterized tests positions.
-- All parameterized test positions should have `is_parameterized` property on it.
---@param positions neotest.Tree
---@return neotest.Tree[]
function M.getParameterizedTestsPositions(positions)
  local parameterized_tests_positions = {}

  for _, tree in positions:iter_nodes() do
    local pos = tree:data()

    if isTestOrNamespace(pos) and M.isPositionParameterized(tree, pos) then
      table.insert(parameterized_tests_positions, tree)
    end
  end

  return parameterized_tests_positions
end

-- Synchronously runs `jest` in `file_path` directory skipping all tests and returns `jest` output.
-- Output have all of the test names inside it. It skips all tests by adding
-- extra `--testPathPattern` parameter to jest command with placeholder string that should never exist.
-- @param file_path string - path to file to search for tests
-- @return table - parsed jest test results
local function runJestTestDiscovery(file_path)
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
---@return table<integer, neotest-jest.RuntimeTestInfo[]>
local function getTestsByPosition(jest_output)
  ---@type table<integer, neotest-jest.RuntimeTestInfo[]>
  local tests_by_position = {}

  for _, testResult in pairs(jest_output.testResults) do
    local testFile = testResult.name

    for _, assertionResult in pairs(testResult.assertionResults) do
      local line, name = assertionResult.location.line - 1, assertionResult.title
      local pos_id = jest_util.getNeotestPositionIdFromTestResult(testFile, assertionResult)

      if not tests_by_position[line] then
        tests_by_position[line] = {}
      end

      table.insert(tests_by_position[line], {
        pos_id = pos_id,
        name = name,
      })
    end
  end

  return tests_by_position
end

--- Create a range-less (range = nil) child node for an existing tree
---@param tree neotest.Tree
---@param pos neotest.Position
---@return neotest.Tree
local function createNewChildNode(tree, pos)
  -- WARNING: The following code relies on neotest internals
  local new_pos = pos
  new_pos.range = nil

  ---@diagnostic disable-next-line: invisible
  local new_tree = types.Tree:new(new_pos, {}, tree._key, nil, nil)

  -- FIX: This does not work when the parametric test does not use the
  -- parameters as the position id will be the same and will overwrite
  -- the existing child (the source-level parametric test)

  ---@diagnostic disable-next-line: invisible
  tree:add_child(new_pos.id, new_tree)

  return new_tree
end

--- Creates namespaces nodes for a position if they do not already exist and
--- returns the namespace node for which to create test nodes under
---@param tree neotest.Tree
---@param pos_id string
---@return neotest.Tree?
local function tryCreateNamespaceNodes(tree, pos_id)
  local parts = vim.split(pos_id, "::")

  if #parts <= 2 then
    -- Only the path and test name
    return
  end

  ---@param _tree neotest.Tree?
  ---@param pos_id_parts string[]
  ---@return neotest.Tree?
  local function recurseTree(_tree, pos_id_parts)
    if not _tree then
      return
    end

    -- We are at the top which is the file position
    if #pos_id_parts == 1 then
      return _tree
    end

    local parent_pos_id_parts = vim.list_slice(pos_id_parts, 1, #pos_id_parts - 1)
    local parent_tree = recurseTree(_tree:parent(), parent_pos_id_parts)

    if not parent_tree then
      return
    end

    local cur_pos_id = table.concat(pos_id_parts, "::")
    local cur_tree = parent_tree:get_key(cur_pos_id)

    -- If the namespace node already exists, another parametric test in the
    -- same namespace created it before us so just return that tree, otherwise
    -- create it
    if cur_tree then
      return cur_tree
    else
      return createNewChildNode(
        parent_tree,
        ---@diagnostic disable-next-line: missing-fields
        {
          id = cur_pos_id,
          name = pos_id_parts[#pos_id_parts],
          type = types.PositionType.namespace,
          path = tree:data().path,
        }
      )
    end
  end

  local namespace_pos_id_parts = vim.list_slice(parts, 1, #parts - 1)

  -- Recurse up the current tree and dynamically create new namespace nodes as
  -- needed, creating top-level nodes before nodes at lower levels
  return recurseTree(tree:parent(), namespace_pos_id_parts)
end

-- Add new tree nodes for parameterized tests to the existing neotest tree
---@param file_path string
---@param parsed_parameterized_tests_positions neotest.Tree[]
function M.enrichPositionsWithParameterizedTests(file_path, parsed_parameterized_tests_positions)
  -- Get all runtime test information for path
  local jest_test_discovery_output = runJestTestDiscovery(file_path)

  logger.warn(jest_test_discovery_output)

  if jest_test_discovery_output == nil then
    return
  end

  local tests_by_position = getTestsByPosition(jest_test_discovery_output)

  -- For each parameterized test, find all tests that were in the same position
  -- as it and add new range-less (range = nil) children to the tree
  for _, tree in pairs(parsed_parameterized_tests_positions) do
    local pos = tree:data()

    if pos.type == types.PositionType.test then
      -- Get all tests for the given position and create child nodes in the
      -- neotest tree
      local parameterized_test_results_for_position = tests_by_position[pos.range[1]] or {}

      -- If we didn't find any test results, it might be because the test is
      -- defined on multiple lines (common with test.each). Since jest reports
      -- test lines at the position of the string name of the test, not the
      -- position of the 'it' or 'test', we try to lookup using that position
      -- instead. The position of a test in the neotest tree is usually the
      -- start and end of the entire test definition which might not be the
      -- same as the line where the string name occurs for multi-line test
      --
      -- test.each([ // <-- Start of neotest match
      --     'a',
      --     'b'
      -- ])('test name') // <-- Position reported by jest
      if #parameterized_test_results_for_position == 0 then
        ---@diagnostic disable-next-line: undefined-field
        local test_name_line = pos.test_name_range[1]
        parameterized_test_results_for_position = tests_by_position[test_name_line] or {}
      end

      for _, test_result in ipairs(parameterized_test_results_for_position) do
        local ns_tree = tryCreateNamespaceNodes(tree, test_result.pos_id)

        -- Only create a new node if the test position has any test parameters
        -- ('$param' or '%j') in the name. Otherwise, we would use a position
        -- id that matches the source-level test name which would overwrite
        -- the real position id in the tree.
        --
        -- There is no way for neotest-jest or jest to distinguish between
        -- tests that share the same name anyway so not creating new nodes is
        -- acceptable for now
        -- if hasTestParameters(tree, pos) then
        if not tree:get_key(test_result.pos_id) then
          createNewChildNode(
            ns_tree or tree,
            ---@diagnostic disable-next-line: missing-fields
            {
              id = test_result.pos_id,
              name = test_result.name,
              type = types.PositionType.test,
              path = pos.path,
              -- Add the position id for the original source-level position id
              -- from which this parametric (runtime) test was generated so we
              -- can create a result for it later
              source_pos_id = pos.id,
            }
          )
        end
      end
    end
  end
end

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
    if not isTestOrNamespace(pos) then
      break
    end

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
  local result = test_name:gsub(JEST_NAMED_PARAMETER_REGEX, ".*")

  for _, parameter in ipairs(JEST_PARAMETER_TYPES) do
    result = result:gsub(parameter, ".*")
  end

  return result
end

return M

local util = require("neotest-jest.util")

local M = {}

function M.is_callable(obj)
  return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

-- Returns jest binary from `node_modules` if that binary exists and `jest` otherwise.
---@param path string
---@return string
function M.getJestCommand(path)
  local gitAncestor = util.find_git_ancestor(path)
  vim.print(gitAncestor)

  local function findBinary(p)
    local rootPath = util.find_node_modules_ancestor(p)
    local jestBinary = util.path.join(rootPath, "node_modules", ".bin", "jest")
    vim.print(jestBinary)

    if util.path.exists(jestBinary) then
      return jestBinary
    end

    -- If no binary found and the current directory isn't the parent
    -- git ancestor, let's traverse up the tree again
    if rootPath ~= gitAncestor then
      return findBinary(util.path.dirname(rootPath))
    end
  end

  local foundBinary = findBinary(path)

  if foundBinary then
    return foundBinary
  end

  return "jest"
end

local jestConfigPattern = util.root_pattern("jest.config.{js,ts}")

-- Returns jest config file path if it exists.
---@param path string
---@return string|nil
function M.getJestConfig(path)
  local rootPath = jestConfigPattern(path)

  if not rootPath then
    return nil
  end

  local jestJs = util.path.join(rootPath, "jest.config.js")
  local jestTs = util.path.join(rootPath, "jest.config.ts")

  if util.path.exists(jestTs) then
    return jestTs
  end

  return jestJs
end

-- Returns neotest test id from jest test result.
-- @param testFile string
-- @param assertionResult table
-- @return string
function M.get_test_full_id_from_test_result(testFile, assertionResult)
  local keyid = testFile
  local name = assertionResult.title

  for _, value in ipairs(assertionResult.ancestorTitles) do
    keyid = keyid .. "::" .. value
  end

  keyid = keyid .. "::" .. name

  return keyid
end

return M

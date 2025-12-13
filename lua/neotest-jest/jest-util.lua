local M = {}

local lib = require("neotest.lib")
local util = require("neotest-jest.util")
local compat = require("neotest-jest.compat")
local uv = compat.uv
local rootPackageJsonPath = uv.cwd() .. "/package.json"
local jestConfigPattern = util.root_pattern("jest.config.{js,ts}")

-- Returns jest binary from `node_modules` if that binary exists and `jest` otherwise.
---@param path string
---@return string
function M.getJestCommand(path)
  local gitAncestor = util.find_git_ancestor(path)

  local function findBinary(p)
    local rootPath = util.find_node_modules_ancestor(p)

    if not rootPath then
      -- We did not find a root path so bail out since we already searched a
      -- lot of parent directories. Otherwise we would compare a nil value
      -- with a possible non-nil gitAncestor path resulting in infinite
      -- recursion
      return
    end

    local jestBinary = util.path.join(rootPath, "node_modules", ".bin", "jest")

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

---@param context neotest-jest.JestArgumentContext
---@return string[]
function M.getJestDefaultArguments(context)
  local arguments = {}

  if util.path.exists(context.config) then
    -- Only use config if available
    table.insert(arguments, "--config=" .. context.config)
  end

  return vim.list_extend(arguments, {
    "--no-coverage",
    "--verbose",
    "--json",
    "--outputFile=" .. context.resultsPath,
    "--testNamePattern=" .. context.testNamePattern,
    "--forceExit", -- Ensure jest and thus the adapter does not hang
    "--testLocationInResults", -- Ensure jest outputs test locations
  })
end

---@param defaultArguments string[]
---@param context neotest-jest.JestArgumentContext
---@return string[]
---@diagnostic disable-next-line: unused-local
function M.getJestArguments(defaultArguments, context)
  return defaultArguments
end

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

---@return boolean
local function checkPackageFieldsForJest(parsedPackageJson)
  local fields = { "dependencies", "devDependencies" }

  for _, field in ipairs(fields) do
    if parsedPackageJson[field] then
      for key, _ in pairs(parsedPackageJson[field]) do
        if key == "jest" then
          return true
        end
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

  return false
end

---@param path string
---@return boolean
function M.packageJsonHasJestDependency(path)
  local read_success, packageJsonContent = pcall(lib.files.read, path)

  if not read_success then
    vim.notify("cannot read package.json", vim.log.levels.ERROR)
    return false
  end

  local parse_success, parsedPackageJson = pcall(vim.json.decode, packageJsonContent)

  if not parse_success then
    vim.notify("cannot parse package.json", vim.log.levels.ERROR)
    return false
  end

  return checkPackageFieldsForJest(parsedPackageJson)
end

---@async
---@param path string?
---@return boolean
function M.hasJestDependency(path)
  if not path then
    return false
  end

  local rootPath = lib.files.match_root_pattern("package.json")(path)

  if not rootPath then
    return false
  end

  if M.packageJsonHasJestDependency(rootPath .. "/package.json") then
    return true
  end

  return M.packageJsonHasJestDependency(rootPackageJsonPath)
end

-- Returns neotest test id from jest test result.
---@param testFile string
---@param assertionResult table
---@return string
function M.getNeotestPositionIdFromTestResult(testFile, assertionResult)
  local keyid = testFile
  local name = assertionResult.title

  for _, value in ipairs(assertionResult.ancestorTitles) do
    keyid = keyid .. "::" .. value
  end

  keyid = keyid .. "::" .. name

  return keyid
end

---@async
---@param file_path string?
---@return boolean
function M.defaultIsTestFile(file_path)
  if not file_path then
    return false
  end

  return util.defaultTestFileMatcher(file_path) and M.hasJestDependency(file_path)
end

return M

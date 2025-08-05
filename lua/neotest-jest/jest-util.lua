local util = require("neotest-jest.util")

local M = {}

local lib = require("neotest.lib")

local rootPackageJson = vim.fn.getcwd() .. "/package.json"

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

function M.packageJsonHasJestDependency(packageJsonContent)
  local success, parsedPackageJson = pcall(vim.json.decode, packageJsonContent)

  if not success then
    print("cannot parse package.json")
    return false
  end

  local keys = { "dependencies", "devDependencies" }

  for _, key in ipairs(keys) do
    if parsedPackageJson[key] then
      for subkey, _ in pairs(parsedPackageJson[key]) do
        if subkey == "jest" then
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

---@return boolean
function M.rootProjectHasJestDependency()
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

  local success, packageJsonContent = pcall(lib.files.read, rootPath .. "/package.json")

  if not success then
    print("cannot read package.json")
    return false
  end

  if M.packageJsonHasJestDependency(packageJsonContent) then
    return true
  end

  return M.rootProjectHasJestDependency()
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

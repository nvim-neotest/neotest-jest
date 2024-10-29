local async = require("neotest.async")
local vim = vim
local validate = vim.validate
local uv = vim.loop

local M = {}

-- Some path utilities
M.path = (function()
  local is_windows = uv.os_uname().version:match("Windows")

  local function sanitize(path)
    if is_windows then
      path = path:sub(1, 1):upper() .. path:sub(2)
      path = path:gsub("\\", "/")
    end
    return path
  end

  local function exists(filename)
    local stat = uv.fs_stat(filename)
    return stat and stat.type or false
  end

  local function is_dir(filename)
    return exists(filename) == "directory"
  end

  local function is_file(filename)
    return exists(filename) == "file"
  end

  local function is_fs_root(path)
    if is_windows then
      return path:match("^%a:$")
    else
      return path == "/"
    end
  end

  local function is_absolute(filename)
    if is_windows then
      return filename:match("^%a:") or filename:match("^\\\\")
    else
      return filename:match("^/")
    end
  end

  local function dirname(path)
    local strip_dir_pat = "/([^/]+)$"
    local strip_sep_pat = "/$"
    if not path or #path == 0 then
      return
    end
    local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
    if #result == 0 then
      if is_windows then
        return path:sub(1, 2):upper()
      else
        return "/"
      end
    end
    return result
  end

  local function path_join(...)
    return table.concat(vim.tbl_flatten({ ... }), "/")
  end

  -- Traverse the path calling cb along the way.
  local function traverse_parents(path, cb)
    path = uv.fs_realpath(path)
    local dir = path
    -- Just in case our algo is buggy, don't infinite loop.
    for _ = 1, 100 do
      dir = dirname(dir)
      if not dir then
        return
      end
      -- If we can't ascend further, then stop looking.
      if cb(dir, path) then
        return dir, path
      end
      if is_fs_root(dir) then
        break
      end
    end
  end

  -- Iterate the path until we find the rootdir.
  local function iterate_parents(path)
    local function it(_, v)
      if v and not is_fs_root(v) then
        v = dirname(v)
      else
        return
      end
      if v and uv.fs_realpath(v) then
        return v, path
      else
        return
      end
    end
    return it, path, path
  end

  local function is_descendant(root, path)
    if not path then
      return false
    end

    local function cb(dir, _)
      return dir == root
    end

    local dir, _ = traverse_parents(path, cb)

    return dir == root
  end

  local path_separator = is_windows and ";" or ":"

  return {
    is_dir = is_dir,
    is_file = is_file,
    is_absolute = is_absolute,
    exists = exists,
    dirname = dirname,
    join = path_join,
    sanitize = sanitize,
    traverse_parents = traverse_parents,
    iterate_parents = iterate_parents,
    is_descendant = is_descendant,
    path_separator = path_separator,
  }
end)()

function M.search_ancestors(startpath, func)
  validate({ func = { func, "f" } })
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in M.path.iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

function M.root_pattern(...)
  local patterns = vim.tbl_flatten({ ... })
  local function matcher(path)
    for _, pattern in ipairs(patterns) do
      for _, p in ipairs(vim.fn.glob(M.path.join(path, pattern), true, true)) do
        if M.path.exists(p) then
          return path
        end
      end
    end
  end
  return function(startpath)
    return M.search_ancestors(startpath, matcher)
  end
end

function M.find_node_modules_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    if M.path.is_dir(M.path.join(path, "node_modules")) then
      return path
    end
  end)
end

function M.find_package_json_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    if M.path.is_file(M.path.join(path, "package.json")) then
      return path
    end
  end)
end

function M.find_git_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    -- .git is a file when the project is a git worktree
    -- or it's a directory if it's a regular project
    if M.path.is_file(M.path.join(path, ".git")) or M.path.is_dir(M.path.join(path, ".git")) then
      return path
    end
  end)
end

-- Note: this function is almost entirely taken from https://github.com/nvim-neotest/neotest/blob/master/lua/neotest/lib/file/init.lua#L93-L144
-- The only difference is that neotest function reads only new lines and this one reads and returns the whole file
--- Streams data from a file, watching for new data over time
--- Each time new data arrives function reads whole file and returns its content
--- Useful for watching a file which is written to by another process.
---@async
---@param file_path string
---@return (fun(): string, fun()) Iterator and callback to stop streaming
function M.stream(file_path)
  local queue = async.control.queue()
  local read_semaphore = async.control.semaphore(1)

  local open_err, file_fd = async.uv.fs_open(file_path, "r", 438)
  assert(not open_err, open_err)

  local exit_future = async.control.future()
  local read = function()
    read_semaphore.with(function()
      local stat_err, stat = async.uv.fs_fstat(file_fd)
      assert(not stat_err, stat_err)
      local read_err, data = async.uv.fs_read(file_fd, stat.size, 0)
      assert(not read_err, read_err)
      queue.put(data)
    end)
  end

  read()
  local event = vim.loop.new_fs_event()
  event:start(file_path, {}, function(err, _, _)
    assert(not err)
    async.run(read)
  end)

  local function stop()
    exit_future.wait()
    event:stop()
    local close_err = async.uv.fs_close(file_fd)
    assert(not close_err, close_err)
  end

  async.run(stop)

  return queue.get, exit_future.set
end

---@return string[]
---@return string[]
function M.default_test_extensions()
  return { "spec", "e2e%-spec", "test", "unit", "regression", "integration" }, {
    "js",
    "jsx",
    "coffee",
    "ts",
    "tsx",
  }
end

---@param intermediate_extensions string[]
---@param end_extensions string[]
---@return fun(file_path: string): boolean
function M.create_test_file_extensions_matcher(intermediate_extensions, end_extensions)
  return function(file_path)
    if file_path == nil then
      return false
    end

    for _, iext in ipairs(intermediate_extensions) do
      for _, eext in ipairs(end_extensions) do
        if string.match(file_path, "%." .. iext .. "%." .. eext .. "$") then
          return true
        end
      end
    end

    return false
  end
end

return M

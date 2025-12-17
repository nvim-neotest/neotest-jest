local compat = {}

compat.uv = vim.uv or vim.loop

---@param tbl table
---@return table
function compat.tbl_flatten(tbl)
  ---@diagnostic disable-next-line: deprecated
  return vim.iter and vim.iter(tbl):flatten():totable() or vim.tbl_flatten(tbl)
end

---@param tbl table
---@return boolean
function compat.tbl_islist(tbl)
  if vim.fn.has("nvim-0.10.0") == 1 then
    return vim.islist(tbl)
  end

  ---@diagnostic disable-next-line: deprecated
  return vim.tbl_islist(tbl)
end

return compat

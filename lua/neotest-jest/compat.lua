local compat = {}

---@param tbl table
---@return table
function compat.tbl_flatten(tbl)
  if vim.fn.has("nvim-0.13.0") then
    return vim.iter(tbl):flatten():totable()
  end

  ---@diagnostic disable-next-line: deprecated
  return vim.tbl_flatten(tbl)
end

return compat

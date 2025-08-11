local notifications = {}

---@param message string
---@param level integer
local function _notify(message, level)
    vim.notify(message, level, { title = "neotest-jest" })
end

---@param message string
function notifications.error(message)
    _notify(message, vim.log.levels.ERROR)
end

---@param message string
function notifications.warn(message)
    _notify(message, vim.log.levels.WARN)
end

return notifications

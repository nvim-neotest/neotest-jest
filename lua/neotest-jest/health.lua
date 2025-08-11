local health = {}

local compat = require("neotest-jest.compat")
local config = require("neotest-jest.config")

local min_neovim_version = "0.9.0"
local report_start, report_ok, report_error = compat.get_report_funcs()

---@param module_name string
local function check_module_installed(module_name)
    local installed, _ = pcall(require, module_name)

    if installed then
        report_ok(("`%s` is installed"):format(module_name))
    else
        report_error(("`%s` is not installed"):format(module_name))
    end
end

function health.check()
    report_start("neotest-jest")

    if vim.fn.has("nvim-" .. min_neovim_version) == 1 then
        report_ok(("has neovim %s+"):format(min_neovim_version))
    else
        report_error("neotest-jest requires at least neovim " .. min_neovim_version)
    end

    -- NOTE: We cannot check the neotest version because it isn't advertised as
    -- part of its public api
    check_module_installed("neotest")
    check_module_installed("nio")

    local ok, error = config.validate(config)

    if ok then
        report_ok("found no errors in config")
    else
        report_error("config has errors: " .. error)
    end
end

return health

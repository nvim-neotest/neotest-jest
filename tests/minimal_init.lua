-- Update the paths below to match your local installations of the plugins
vim.opt.rtp:append(".")
vim.opt.rtp:append("~/.local/share/nvim/lazy/plenary.nvim")
vim.opt.rtp:append("~/.local/share/nvim/lazy/nvim-nio")
vim.opt.rtp:append("~/.local/share/nvim/lazy/nvim-treesitter")

vim.cmd.runtime({ "plugin/plenary.vim", bang = true })

require("neotest").setup({
  log_level = vim.log.levels.WARN,
})

vim.print(vim.inspect(require("nvim-treesitter.config").get_installed("parsers")))

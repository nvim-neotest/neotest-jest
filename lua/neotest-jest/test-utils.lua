local test_utils = {}

--- Force a load of the vim.treesitter modules so that any side-effects executed
--- by the load are done outside of an async context. This way the next call to
--- a vim.treesitter module will work in an async context.
---
--- See https://github.com/neovim/neovim/issues/35071 for more details
function test_utils.prepare_vim_treesitter()
  vim.treesitter.language.get_lang("lua")
end

return test_utils

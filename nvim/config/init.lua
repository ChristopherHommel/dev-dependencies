if vim.fn.has("nvim-0.9") ~= 1 then
  vim.api.nvim_err_writeln("This Neovim config requires Neovim 0.9 or newer. Use /usr/local/bin/nvim or rerun the dev-dependencies Neovim installer.")
  return
end

require("options")
require("keymaps")
require("plugins")

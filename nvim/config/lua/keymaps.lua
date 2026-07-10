local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })

local function telescope_builtin(name)
  return function()
    local ok, builtin = pcall(require, "telescope.builtin")
    if ok then
      builtin[name]()
    else
      vim.notify("telescope.nvim is not installed", vim.log.levels.WARN)
    end
  end
end

map("n", "<leader>ff", telescope_builtin("find_files"), { desc = "Find files" })
map("n", "<leader>fg", telescope_builtin("live_grep"), { desc = "Live grep" })
map("n", "<leader>fb", telescope_builtin("buffers"), { desc = "Find buffers" })
map("n", "<leader>fh", telescope_builtin("help_tags"), { desc = "Help tags" })
map("n", "<leader>fr", telescope_builtin("oldfiles"), { desc = "Recent files" })

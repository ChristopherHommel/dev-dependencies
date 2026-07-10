local M = {}

local function on_attach(_, bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gr", vim.lsp.buf.references, "Find references")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("n", "<leader>e", vim.diagnostic.open_float, "Show line diagnostics")
  map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
  map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
end

local function capabilities()
  local base = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

  if ok then
    return cmp_nvim_lsp.default_capabilities(base)
  end

  return base
end

local function setup_java(capabilities_value)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function(args)
      local ok, jdtls = pcall(require, "jdtls")
      if not ok then
        vim.notify("nvim-jdtls is not installed", vim.log.levels.WARN)
        return
      end

      local util = require("lspconfig.util")
      local root_dir = util.root_pattern("pom.xml", "build.gradle", "settings.gradle", ".git")(args.file)

      if root_dir == nil then
        return
      end

      local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
      local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

      jdtls.start_or_attach({
        cmd = { "jdtls", "-data", workspace_dir },
        root_dir = root_dir,
        capabilities = capabilities_value,
        on_attach = on_attach,
        settings = {
          java = {
            configuration = {
              updateBuildConfiguration = "interactive",
            },
            import = {
              gradle = { enabled = true },
              maven = { enabled = true },
            },
          },
        },
      })
    end,
  })
end

function M.setup()
  local mason_ok, mason = pcall(require, "mason")
  if mason_ok then
    mason.setup()
  end

  local servers = {
    "lua_ls",
    "pyright",
    "ts_ls",
    "rust_analyzer",
    "gopls",
    "bashls",
    "jdtls",
  }

  local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if mason_lspconfig_ok then
    mason_lspconfig.setup({
      ensure_installed = servers,
    })
  end

  local lspconfig = require("lspconfig")
  local capabilities_value = capabilities()

  local server_settings = {
    lua_ls = {
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    },
  }

  for _, server in ipairs(servers) do
    if server ~= "jdtls" and lspconfig[server] ~= nil then
      lspconfig[server].setup(vim.tbl_deep_extend("force", {
        capabilities = capabilities_value,
        on_attach = on_attach,
      }, server_settings[server] or {}))
    end
  end

  setup_java(capabilities_value)
end

return M

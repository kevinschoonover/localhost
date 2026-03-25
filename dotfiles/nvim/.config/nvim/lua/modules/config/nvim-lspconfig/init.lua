local capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())

local on_attach = function(client, bufnr)
  if client.name == "ts_ls" then
    -- disable tslint formatting in favor of other formatters
    client.server_capabilities.documentFormattingProvider = false
  end

  -- if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, bufnr) then
  --   vim.lsp.inline_completion.enable(true, { bufnr = bufnr })

  --   vim.keymap.set(
  --     'i',
  --     '<C-F>',
  --     vim.lsp.inline_completion.get,
  --     { desc = 'LSP: accept inline completion', buffer = bufnr }
  --   )
  --   vim.keymap.set(
  --     'i',
  --     '<C-G>',
  --     vim.lsp.inline_completion.select,
  --     { desc = 'LSP: switch inline completion', buffer = bufnr }
  --   )
  -- end


  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format { timeout_ms = 5000 }
      end,
    })
  end

  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = 'LSP: [R]e[n]ame' })
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'LSP: [C]ode [A]ction' })

  vim.keymap.set('n', 'gd', require('telescope.builtin').lsp_definitions, { buffer = bufnr, desc = 'LSP: [G]oto [D]efinition' })
  vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, { buffer = bufnr, desc = 'LSP: [G]oto [R]eferences' })
  vim.keymap.set('n', 'gI', require('telescope.builtin').lsp_implementations, { buffer = bufnr, desc = 'LSP: [G]oto [I]mplementation' })
  vim.keymap.set('n', '<leader>D', require('telescope.builtin').lsp_type_definitions, { buffer = bufnr, desc = 'LSP: Type [D]efinition' })
  vim.keymap.set('n', '<leader>ds', require('telescope.builtin').lsp_document_symbols, { buffer = bufnr, desc = 'LSP: [D]ocument [S]ymbols' })
  vim.keymap.set('n', '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, { buffer = bufnr, desc = 'LSP: [W]orkspace [S]ymbols' })

  -- See `:help K` for why this keymap
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'LSP: Hover Documentation' })
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { buffer = bufnr, desc = 'LSP: Signature Documentation' })

  -- Lesser used LSP functionality
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = 'LSP: [G]oto [D]eclaration' })
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { buffer = bufnr, desc = 'LSP: [W]orkspace [A]dd Folder' })
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { buffer = bufnr, desc = 'LSP: [W]orkspace [R]emove Folder' })
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, { buffer = bufnr, desc = 'LSP: [W]orkspace [L]ist Folders' })

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end

vim.filetype.add {
  pattern = {
    ['openapi.*%.ya?ml'] = 'yaml.openapi',
    ['openapi.*%.json'] = 'json.openapi',
  },
}

local eslint_base_on_attach = vim.lsp.config.eslint.on_attach

require('fidget').setup({})
require('neodev').setup()

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
local lsps = {
  { "lua_ls", {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
      Lua = {
        diagnostics = {
          globals = { 'vim' }
        },
        workspace = {
          -- checkThirdParty = "Disable",
          checkThirdParty = false,
        }
      }
    }
  } },
  { "jsonls", {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
      json = {
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    }
  } },
  { "yamlls", {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
      yaml = {
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    }
  } },
  { "gopls", {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
      gopls = {
        semanticTokens = true,
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        gofumpt = true,
      },
    }
  } },
  { "rust_analyzer", {
    on_attach = on_attach,
    capabilities = capabilities,

    settings = {
      ['rust-analyzer'] = {
        checkOnSave = {
          allFeatures = true,
          overrideCommand = {
            'cargo', 'clippy', '--workspace', '--message-format=json',
            '--all-targets', '--all-features'
          }
        }
      }
    }
  } },
  { "ts_ls", {
    on_attach = on_attach,
    capabilities = capabilities,

  } },
  { "bashls", {
    on_attach = on_attach,
    capabilities = capabilities,

  } },
  { "nil_ls", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "marksman", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "cmake", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "ccls", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "vacuum", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "eslint", {
    on_attach = function(client, bufnr)
      if not eslint_base_on_attach then
        error("eslint on_attach function not found")
        return
      end

      on_attach(client, bufnr)
      eslint_base_on_attach(client, bufnr)
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
          vim.cmd.LspEslintFixAll()
        end,
      })
    end,
    capabilities = capabilities,
  } },
  {
    "golangci_lint_ls", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "ruff", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  { "basedpyright", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
  {
    "copilot", {
    on_attach = on_attach,
    capabilities = capabilities,
  } },
}

for _, lsp in pairs(lsps) do
  local name, config = lsp[1], lsp[2]
  vim.lsp.enable(name)
  if config then
    vim.lsp.config(name, config)
  end
end

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true,   -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { float = true },
}

vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end,
  { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end,
  { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

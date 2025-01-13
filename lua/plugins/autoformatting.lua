return {
	"nvimtools/none-ls.nvim",
	dependencies = {
   'nvim-lua/plenary.nvim',
		"nvimtools/none-ls-extras.nvim",
		"jayp0521/mason-null-ls.nvim", -- ensure dependencies are installed
	},
	config = function()
		local null_ls = require("null-ls")
		local formatting = null_ls.builtins.formatting -- to setup formatters
		local diagnostics = null_ls.builtins.diagnostics -- to setup linters

		-- Formatters & linters for mason to install
		require("mason-null-ls").setup({
			ensure_installed = {
				"prettier", -- ts/js formatter
				"stylua", -- lua formatter
				"shfmt", -- Shell formatter
				"checkmake", -- linter for Makefiles
				"ruff", -- Python linter and formatter
				"csharpier",
			},
			automatic_installation = true,
		})

		local sources = {
			-- Diagnostics
			diagnostics.checkmake,
			-- Formatting
			formatting.prettier.with({
				filetypes = {
					"javascript",
					"typescript",
					"javascriptreact",
					"typescriptreact",
					"html",
					"json",
					"yaml",
					"markdown",
				},
			}),
			formatting.csharpier.with({ filetypes = { "cs" } }),
			formatting.stylua,
			formatting.shfmt.with({ args = { "-i", "4" } }),
			formatting.terraform_fmt,
			require("none-ls.formatting.ruff").with({ extra_args = { "--extend-select", "I" } }),
			require("none-ls.formatting.ruff_format"),
		}

		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
		null_ls.setup({
			-- debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
			sources = sources,
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ async = true, timeout_ms = 2000 }) -- Ensure this is async
						end,
					})
				end
			end,
		})
	end,
}

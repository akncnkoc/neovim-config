return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for Neovim
		{
			"williamboman/mason.nvim",
			config = true,
			opts = { ensure_installed = { "gitui" } },
			keys = {
				vim.keymap.set("n", "<leader>gg", function()
					-- Open a terminal and run `gitui` in the current working directory
					vim.cmd("split | terminal gitui")
				end, { noremap = true, silent = true, desc = "GitUi (Root Dir)" }),
			},
		}, -- NOTE: Must be loaded before dependants
		"Hoffs/omnisharp-extended-lsp.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end
				-- map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end
				if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, "[T]oggle Inlay [H]ints")
				end
				if client and client.name == "omnisharp" then
					map("gd", require("omnisharp_extended").telescope_lsp_definition, "g]oto [d]efinition")
				end
			end,
		})

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
		local servers = {
			clangd = {},
			omnisharp = {
				root_dir = function(fname)
					local util = require("lspconfig.util")
					return util.root_pattern("*.sln")(fname) or util.root_pattern("*.csproj")(fname)
				end,
				settings = {
					FormattingOptions = {
						EnableEditorConfigSupport = true,
						OrganizeImports = nil,
					},
					RoslynExtensionsOptions = {
						EnableAnalyzersSupport = false,
						EnableImportCompletion = true,
						AnalyzeOpenDocumentsOnly = false,
					},
				},
				handlers = {
					["textDocument/definition"] = require("omnisharp_extended").handler,
					["textDocument/typeDefinition"] = require("omnisharp_extended").handler,
				},
			},
			gopls = {},
			ts_ls = {},
			ruff = {},
			pylsp = {
				settings = {
					pylsp = {
						plugins = {
							pyflakes = { enabled = false },
							pycodestyle = { enabled = false },
							autopep8 = { enabled = false },
							yapf = { enabled = false },
							mccabe = { enabled = false },
							pylsp_mypy = { enabled = false },
							pylsp_black = { enabled = false },
							pylsp_isort = { enabled = false },
						},
					},
				},
			},
			html = { filetypes = { "html", "twig", "hbs" } },
			cssls = {},
			tailwindcss = {},
			dockerls = {},
			terraformls = {},
			jsonls = {},
			yamlls = {},
			lua_ls = {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = {
								"${3rd}/luv/library",
								unpack(vim.api.nvim_get_runtime_file("", true)),
							},
						},
						diagnostics = { disable = { "missing-fields" } },
						format = {
							enable = false,
						},
					},
				},
			},
		}

		require("mason").setup()

		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format Lua code
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})

		vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
			if err then
				vim.notify("LSP Error: " .. err.message, vim.log.levels.ERROR)
				return
			end

			if not result or vim.tbl_isempty(result) then
				vim.notify("No definition found", vim.log.levels.WARN)
				return
			end

			local target = vim.tbl_islist(result) and result[1] or result
			local uri = target.uri or target.targetUri
			local range = target.range or target.targetSelectionRange

			if not uri or not range then
				vim.notify("Invalid LSP response: URI or range missing", vim.log.levels.ERROR)
				return
			end

			local bufnr = vim.uri_to_bufnr(uri)
			if not vim.api.nvim_buf_is_valid(bufnr) then
				vim.notify("Invalid buffer: " .. uri, vim.log.levels.ERROR)
				return
			end

			vim.fn.bufload(bufnr) -- Ensure the buffer is loaded
			vim.api.nvim_set_current_buf(bufnr)

			local lines = vim.api.nvim_buf_line_count(bufnr)
			local line = math.min(range.start.line + 1, lines) -- Clamp line to valid range
			local col = math.max(range.start.character, 0) -- Ensure column is non-negative

			if line > lines then
				vim.notify("Cursor position outside buffer: Line " .. line, vim.log.levels.WARN)
				return
			end

			vim.api.nvim_win_set_cursor(0, { line, col })
		end
	end,
}

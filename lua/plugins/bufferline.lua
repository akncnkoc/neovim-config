return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
	keys = {
		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
		{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
		{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
		{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
		{ "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
		{ "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
		{ "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
		{ "[B", "<cmd>BufferLineMovePrev<CR>", desc = "Move Buffer Prev" },
		{ "]B", "<cmd>BufferLineMoveNext<CR>", desc = "Move Buffer Next" },
	},
	opts = {
		options = {
			close_command = ":bdelete",
			diagnostics = "nvim_lsp",
			always_show_bufferline = false,
			diagnostics_indicator = function(_, _, diag)
				local icons = {
					Error = " ",
					Warn = " ",
				}
				local ret = (diag.error and icons.Error .. diag.error .. " " or "")
					.. (diag.warning and icons.Warn .. diag.warning or "")
				return vim.trim(ret)
			end,
			offsets = {
				{
					filetype = "neo-tree",
					text = "Neo-tree",
					highlight = "Directory",
					text_align = "left",
				},
			},
			get_element_icon = function(opts)
				local icons = {
					lua = "",
					python = "",
					javascript = "",
				}
				return icons[opts.filetype] or ""
			end,
		},
	},
	config = function(_, opts)
		require("bufferline").setup(opts)
		vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
			callback = function()
				vim.schedule(function()
					pcall(require("bufferline").refresh)
				end)
			end,
		})
	end,
}

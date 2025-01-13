return {
	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		opts = {},
	},

	{
		"neovim/nvim-lspconfig",
		opts = function()
			vim.keymap.set("n", "<leader>cr", ":IncRename ")
		end,
	},

	--- Noice integration
	{
		"folke/noice.nvim",
		optional = true,
		opts = {
			presets = { inc_rename = true },
		},
	},
}

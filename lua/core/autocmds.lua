vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			require("neo-tree").show() -- Replace with your file explorer command
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
	pattern = "*",
	command = "silent! w",
})
vim.cmd("set hidden")

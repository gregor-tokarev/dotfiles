return {
	'nvim-telescope/telescope.nvim',
	tag = '0.1.6',
	dependencies = { { 'nvim-lua/plenary.nvim' } },
	config = function()
		local builtin = require('telescope.builtin')
		vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
		vim.keymap.set('n', '<leader>pg', builtin.git_files, {})
        vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
		-- vim.keymap.set('n', '<leader>ps', function()
		-- 	builtin.grep_string({ search = vim.fn.input("Grep > ") })
		-- end)

		require("telescope").setup({
			defaults = {
				file_ignore_patterns = {
					"node_modules",
					"vendor",
					".turbo",
					".expo",
					".vscode",
					".idea",
					"dist",
					"output",
					"./target"
				}
			}
		})
	end
}

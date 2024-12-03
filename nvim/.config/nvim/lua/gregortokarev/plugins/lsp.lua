return {
	"neovim/nvim-lspconfig",

	cmd = { "LspInfo", "LspInstall", "LspStart" },
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "williamboman/mason-lspconfig.nvim" },
	},
	config = function()
		-- This is where all the LSP shenanigans will live
		local lsp_zero = require("lsp-zero")
		lsp_zero.extend_lspconfig()

		--- if you want to know more about lsp-zero and mason.nvim
		--- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
		lsp_zero.on_attach(function(_client, bufnr)
			-- see :help lsp-zero-keybindings
			-- to learn the available actions
			lsp_zero.default_keymaps({ buffer = bufnr })
		end)

		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"rust_analyzer",
				"tsserver",
				"volar",
				"tailwindcss",
				"angularls",
				"ansiblels",
				"astro",
				"somesass_ls",
				"cssls",
				"eslint_d",
				"mdx_analyzer",
				"gopls",
			},
			handlers = {
				-- this first function is the "default handler"
				-- it applies to every language server without a "custom handler"
				function(server_name)
					require("lspconfig")[server_name].setup({})
				end,
				["tsserver"] = function()
					local function organize_imports()
						local params = {
							command = "_typescript.organizeImports",
							arguments = { vim.api.nvim_buf_get_name(0) },
							title = "",
						}
						vim.lsp.buf.execute_command(params)
					end

					vim.keymap.set("n", "<leader>oi", organize_imports, {})

					local vue_typescript_plugin = require("mason-registry")
						.get_package("vue-language-server")
						:get_install_path() .. "/node_modules/@vue/language-server" .. "/node_modules/@vue/typescript-plugin"

					require("lspconfig").tsserver.setup({
						init_options = {
							plugins = {
								{
									name = "@vue/typescript-plugin",
									location = vue_typescript_plugin,
									languages = { "javascript", "typescript", "vue" },
								},
							},
						},
						filetypes = {
							"javascript",
							"javascriptreact",
							"javascript.jsx",
							"typescript",
							"typescriptreact",
							"typescript.tsx",
							"vue",
						},
					})
				end,
			},
		})
	end,
}

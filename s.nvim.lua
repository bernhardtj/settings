-- .config/nvim/init.lua

function EnsurePackage(url)
	local ep_prefix
	ep_prefix = vim.fn.stdpath("data") .. "/site/pack/ensurepackage/opt/"
	if vim.fn.isdirectory(ep_prefix .. url) == 0 then
		vim.cmd("!git clone --depth 1 --filter blob:none https://" .. url .. " " .. ep_prefix .. url)
	end
	vim.cmd("packadd! " .. url)
end

EnsurePackage("github.com/folke/lazy.nvim.git")

vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

require("lazy").setup({
	spec = {
		{
			"NvChad/NvChad",
			lazy = false,
			branch = "v2.5",
			import = "nvchad.plugins",
		},

		{
			"github/copilot.vim",
			lazy = false,
		},

		{
			"stevearc/conform.nvim",
			-- event = 'BufWritePre', -- uncomment for format on save
			opts = {
				formatters_by_ft = {
					lua = { "stylua" },
					-- css = { "prettier" },
					-- html = { "prettier" },
				},

				-- format_on_save = {
				--   -- These options will be passed to conform.format()
				--   timeout_ms = 500,
				--   lsp_fallback = true,
				-- },
			},
		},

		-- These are some examples, uncomment them if you want to see them work!
		{
			"neovim/nvim-lspconfig",
			config = function()
				-- load defaults i.e lua_lsp
				require("nvchad.configs.lspconfig").defaults()

				local nvlsp = require("nvchad.configs.lspconfig")

				-- EXAMPLE
				local servers = { "html", "cssls", "pyright", "bashls", "rust_analyzer"}

				-- lsps with default config
				for _, lsp in ipairs(servers) do
					vim.lsp.config[lsp] = {
						cmd = vim.lsp.config[lsp].cmd,
						filetypes = vim.lsp.config[lsp].filetypes,
						root_markers = vim.lsp.config[lsp].root_markers,
						on_attach = nvlsp.on_attach,
						on_init = nvlsp.on_init,
						capabilities = nvlsp.capabilities,
					}
					vim.lsp.enable(lsp)
				end

				-- configuring single server, example: texlab
				vim.lsp.config.texlab = {
					cmd = { "texlab" },
					filetypes = { "tex", "plaintex", "bib" },
					root_markers = { ".git", ".latexmkrc" },
					on_attach = nvlsp.on_attach,
					on_init = nvlsp.on_init,
					capabilities = nvlsp.capabilities,
					settings = {
						texlab = {
							auxDirectory = ".",
							bibtexFormatter = "texlab",
							build = {
								args = { "-X", "compile", "%f", "--synctex", "--keep-logs", "--keep-intermediates" },
								executable = "tectonic",
								forwardSearchAfter = true,
								onSave = true,
							},
							chktex = {
								onEdit = true,
								onOpenAndSave = true,
							},
							diagnosticsDelay = 300,
							formatterLineLength = 80,
							forwardSearch = {
								executable = "evince-synctex",
								args = { "-f", "%l", "%p", '"code -g %f:%l"' },
							},
							latexFormatter = "latexindent",
							latexindent = {
								modifyLineBreaks = false,
							},
						},
					},
				}
				vim.lsp.enable("texlab")
			end,
		},

		-- {
		-- 	"nvim-treesitter/nvim-treesitter",
		-- 	opts = {
		-- 		ensure_installed = {
		-- 			"vim", "lua", "vimdoc",
		--      "html", "css"
		-- 		},
		-- 	},
		-- }, },
	},

	defaults = { lazy = true },
	install = { colorscheme = { "nvchad" } },

	ui = {
		icons = {
			ft = "",
			lazy = "󰂠 ",
			loaded = "",
			not_loaded = "",
		},
	},

	performance = {
		rtp = {
			disabled_plugins = {
				"2html_plugin",
				"tohtml",
				"getscript",
				"getscriptPlugin",
				"gzip",
				"logipat",
				"netrw",
				"netrwPlugin",
				"netrwSettings",
				"netrwFileHandlers",
				"matchit",
				"tar",
				"tarPlugin",
				"rrhelper",
				"spellfile_plugin",
				"vimball",
				"vimballPlugin",
				"zip",
				"zipPlugin",
				"tutor",
				"rplugin",
				"syntax",
				"synmenu",
				"optwin",
				"compiler",
				"bugreport",
				"ftplugin",
			},
		},
	},
})

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require("nvchad.options")

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

require("nvchad.autocmds")

vim.schedule(function()
	require("nvchad.mappings")

	-- add yours here

	local map = vim.keymap.set

	map("n", ";", ":", { desc = "CMD enter command mode" })
	map("i", "jk", "<ESC>")

	-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
end)

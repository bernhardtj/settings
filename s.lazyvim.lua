-- .config/nvim/lua/plugins/custom.lua
return {
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				pyright = {},
				bashls = {},
				texlab = {
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
				},
			},
		},
	},
}

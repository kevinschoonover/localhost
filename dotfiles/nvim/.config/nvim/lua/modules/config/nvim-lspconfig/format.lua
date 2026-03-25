-- ref https://github.com/martinsione/dotfiles/blob/master/src/.config/nvim/lua/modules/config/nvim-lspconfig/format.lua
local eslint = {
	lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
	lintIgnoreExitCode = true,
	lintStdin = true,
	lintFormats = { "%f:%l:%c: %m" },
	formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
	formatStdin = true,
}

local prettier = {
	formatCommand = "prettier --stdin-filepath ${INPUT}",
	formatStdin = true,
}

local black = {
	formatCommand = "`poetry env info -p`/bin/black --fast -",
	formatStdin = true,
}

local isort = {
	formatCommand = "`poetry env info -p`/bin/isort --quiet -",
	formatStdin = true,
}

local hclfmt = {
	formatCommand = "hclfmt",
	formatStdin = true,
}

local pylint = {
	lintCommand = "`poetry env info -p`pylint --output-format text --score no --msg-template {path}:{line}:{column}:{C}:{msg} ${INPUT}",
	lintStdin = false,
	lintFormats = {
		"%f:%l:%c:%t:%m",
	},
	lintOffsetColumns = 1,
	lintCategoryMap = {
		I = "H",
		R = "I",
		C = "I",
		W = "W",
		E = "E",
		F = "E",
	},
}

local stylua = { formatCommand = "stylua -s -", formatStdin = true }

return {
	css = { prettier },
	html = { prettier },
	javascript = { prettier, eslint },
	javascriptreact = { prettier, eslint },
	json = { prettier },
	lua = { stylua },
	markdown = { prettier },
	scss = { prettier },
	typescript = { prettier, eslint },
	typescriptreact = { prettier, eslint },
	yaml = { prettier },
	python = { black, isort, pylint },
	hcl = { hclfmt },
}

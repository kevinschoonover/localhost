local function open_neotree_git_root()
	-- Get the path of the current buffer's file
	local current_file = vim.api.nvim_buf_get_name(0)
	-- Find the project root by searching for the '.git' directory pattern
	local git_root = vim.fs.root(current_file, { ".git" })

	-- If a git root is found, open Neotree at that directory
	if git_root then
		require("neo-tree.command").execute({
			action = "toggle",
			source = "filesystem",
			dir = git_root,
		})
	else
		-- Fallback: open at the current working directory if not in a git repo
		require("neo-tree.command").execute({
			action = "toggle",
			source = "filesystem",
		})
		vim.notify("Not in a Git repository. Opening at CWD.", vim.log.levels.INFO)
	end
end

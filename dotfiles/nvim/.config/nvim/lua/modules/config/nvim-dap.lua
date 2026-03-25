local dapui = require("dapui")
local dap = require("dap")

dapui.setup {}

require('dap-go').setup {}

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

-- https://cs.github.com/AstroNvim/AstroNvim/blob/4f4269d174d85df8b278a6e09d05daeef840df4a/lua/core/mappings.lua?q=lang%3Alua+require%28%22dap%22%29#L265
vim.keymap.set('n', "<F5>", function() require("dap").continue() end, { desc = "dap: Start" })
vim.keymap.set('n', "<F17>", function() require("dap").terminate() end, { desc = "dap: Stop" }) -- Shift+F5)
vim.keymap.set('n', "<F29>", function() require("dap").restart_frame() end, { desc = "dap: Restart" }) -- Control+F5
vim.keymap.set('n', "<F6>", function() require("dap").pause() end, { desc = "dap: Pause" })
vim.keymap.set('n', "<F9>", function() require("dap").toggle_breakpoint() end, { desc = "dap: Toggle Breakpoint" })
vim.keymap.set('n', "<F10>", function() require("dap").step_over() end, { desc = "dap: Step Over" })
vim.keymap.set('n', "<F11>", function() require("dap").step_into() end, { desc = "dap: Step Into" })
vim.keymap.set('n', "<F23>", function() require("dap").step_out() end, { desc = "dap: Step Out" }) -- Shift+F11
vim.keymap.set('n', "<leader>Db", function() require("dap").toggle_breakpoint() end,
	{ desc = "dap: Toggle Breakpoint (F9)" });
vim.keymap.set('n', "<leader>DB", function() require("dap").clear_breakpoints() end, { desc = "dap: Clear Breakpoints" })
vim.keymap.set('n', "<leader>Dc", function() require("dap").continue() end, { desc = "dap: Start/Continue (F5)" })
vim.keymap.set('n', "<leader>Di", function() require("dap").step_into() end, { desc = "dap: Step Into (F11)" })
vim.keymap.set('n', "<leader>Do", function() require("dap").step_over() end, { desc = "dap: Step Over (F10)" })
vim.keymap.set('n', "<leader>DO", function() require("dap").step_out() end, { desc = "dap: Step Out (S-F11)" })
vim.keymap.set('n', "<leader>Dq", function() require("dap").close() end, { desc = "dap: Close Session" })
vim.keymap.set('n', "<leader>DQ", function() require("dap").terminate() end, { desc = "dap: Terminate Session (S-F5)" })
vim.keymap.set('n', "<leader>Dp", function() require("dap").pause() end, { desc = "dap: Pause (F6)" })
vim.keymap.set('n', "<leader>Dr", function() require("dap").restart_frame() end, { desc = "dap: Restart (C-F5)" })
vim.keymap.set('n', "<leader>DR", function() require("dap").repl.toggle() end, { desc = "dap: Toggle REPL" })
vim.keymap.set('n', "<leader>Du", function() require("dapui").toggle() end, { desc = "dap-ui: Toggle" })
vim.keymap.set('n', "<leader>Dh", function() require("dap.ui.widgets").hover() end, { desc = "dap-ui: Hover" })

vim.keymap.set('n', "<leader>Dt", function() require("dap-go").hover() end,
	{ desc = "dap: Debug Go test closest to cursor" })
vim.keymap.set('n', "<leader>DT", function() require("dap-go").hover() end, { desc = "dap: Debug last go test" })

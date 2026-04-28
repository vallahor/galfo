local M = {
	focus_on_click = true,

	base_highlights = {
		visible = { default = "TablineVisible", modified = "" },
		focused = { default = "TablineFocused", modified = "" },
	},

	session_dir = vim.fn.stdpath("data") .. "/galfo",

	scratch_buffer_name = "[No Name]",

	-- Only useful if on windows.
	force_unix_path_sep = true,

	-- There are cases where the width of the tabline can't accommodate the last icon
	-- before the truncate_right, so it will blend with the
	-- next char or being half displayed if no truncate_right.
	-- If don't matter that happening set it to true.
	last_icon_blend = false,

	-- the `on_click` applies to the entire tab without `on_click`
	-- parameters the default on_click parameters and tab.
	-- `tab`
	-- bufnr: integer
	-- focus()
	-- close() -- receive the force (boolean) parameter to force delete the buffer
	-- toggle_pin() -- receive the force (boolean) parameter to force delete the buffer
	tab = {
		on_click = function(tab, _clicks, button, _mods)
			if button == "l" then
				tab.focus()
			elseif button == "m" then
				tab.close(false)
			end
		end,
	},

	-- Each tab could be text, static or icon
	-- `text`: fuction(tab) end
	-- `static`: "" -- just a string
	-- `icon`: function(icon, tab) end -- icon is the filetype string. must return just 1 icon.
	-- And if the highlights in this case are no passed it applies the provider filetype color.
	-- If using some custom icon you should provide the highlight group
	-- Or just `highlights = {}` to use the defaults.
	-- `on_click`: function(bufnr, clicks, button, mods) end
	-- the `tab` parameter is:
	-- name: string
	-- unique_prefix: string -- with a path if a file with the same name appears.
	-- index: integer
	-- is_focused: boolean
	-- is_modified: boolean
	-- is_pinned: boolean
	-- diagnostics: {[vim.diagnostic.severity]: integer} -- Eg.: ab.diagnostics[vim.diagnostic.severity.ERROR]
	--
	-- `highlights`: It receives the highlight group.
	-- You can customize existing colors using:
	-- `Galfo.derive_hl` (returns new group)
	-- `Galfo.get_hex` (return { fg: string, bf: string })
	-- Diagnostics overrides the default and is applied using `diagnostic.filter`
	-- highlights = {
	--   visible = { default = "", modified = "" },
	--   focused = { default = "", modified = "" },
	--   diagnostics = {
	--     error = {
	--       focused = { default = "", modified = "" },
	--       visible = { default = "", modified = "" },
	--     },
	--     warn = {
	--       focused = { default = "", modified = "" },
	--       visible = { default = "", modified = "" },
	--     },
	--   },
	-- },

	tabs = {
		{
			static = " ",
			highlights = {
				visible = { default = "TablineVisible", modified = "TablineVisible" },
				focused = { default = "TablineFocused", modified = "TablineFocused" },
			},
		},
		{
			-- Attention: for icons just return 1 icon each time.
			icon = function(icon, _tab)
				-- return _tab.is_pinned and "󰐃" or icon
				return icon
			end,
			-- on_click = function(buf)
			--   galfo.toggle_pin(buf)
			-- end,
		},
		{
			static = " ",
			highlights = {
				visible = { default = "TablineVisible", modified = "TablineVisible" },
				focused = { default = "TablineFocused", modified = "TablineFocused" },
			},
		},
		{
			text = function(tab)
				return tab.unique_prefix .. tab.name
			end,
		},
		{
			static = " ",
			highlights = {
				visible = { default = "TablineVisible", modified = "TablineVisible" },
				focused = { default = "TablineFocused", modified = "TablineFocused" },
			},
		},
		{
			icon_custom = function()
				return "󰅖"
			end,
			on_click = function(bufnr, clicks, button, mods)
				require("galfo").close_tab(bufnr, false)
			end,
		},
		{
			static = " ",
			highlights = {
				visible = { default = "TablineVisible", modified = "TablineVisible" },
				focused = { default = "TablineFocused", modified = "TablineFocused" },
			},
		},
	},

	diagnostics = {
		filter = { min = vim.diagnostic.severity.WARN, max = vim.diagnostic.severity.ERROR },
		order = {
			vim.diagnostic.severity.ERROR,
			vim.diagnostic.severity.WARN,
			-- vim.diagnostic.severity.INFO,
			-- vim.diagnostic.severity.HINT,
		},
	},

	-- This is for when you want to display some information from diagnostic or react to it
	-- like showing how many errors or warnings.
	-- if diagnostics = true so all other will fallback to it otherwise it will only be
	-- dynamic in the state set.
	-- The index is if you want to display the tab index position.
	-- So it will update whenever that position changes.
	-- dynamic = { index = false, diagnostics = true, focused = { diagnostics = false }, visible = { diagnostics = true } },
	dynamic = { index = true, diagnostics = true },

	-- `first`: appears for the first tab.
	-- `last`: appears for the last tab if tab is fullfilled.
	-- `truncate_left`: appears when theres more tabs left.
	-- `truncate_right`: appears when theres more tabs right.
	indicators = {
		first = { text = "", highlight = "TablineVisible" },
		last = { text = "", highlight = "TablineVisible" },
		truncate_left = { text = "…", highlight = "TablineVisible" },
		truncate_right = { text = "…", highlight = "TablineVisible" },
	},

	-- If you don't want to react too diagnostics or modified just set it up.
	no_diagnostic = false,
	no_modified = false,

	icons = {
		enabled = true,
		provider = "mini.icons", -- "mini.icons"|"nvim-web-devicons" default: "mini.icons"
		-- If the configured provider is not available, galfo will automatically
		-- fallback to the other provider. If neither is available, icons are disabled.
	},

	sidebar = {
		enabled = true,
		label = "Explorer",
		label_position = "mid", -- "start"|"mid"|"end"
		separator = "│",
		filetypes = { "NvimTree", "neo-tree", "aerial" }, -- Default with ["NvimTree", "neo-tree", "aerial"]
		highlights = {
			label = { focused = "TablineFocused", visible = "TablineVisible" },
			sep = "TablineVisible",
		},
	},

	ignore = {
		bufnames = {},
		buftypes = {
			"terminal",
			"prompt",
		},
		filetypes = {
			"qf",
		},
	},

	-- Used when a buffer is deleted/replaced in a window.
	-- That's is for my use case. hehe
	-- I have a bright cursor line in the "current buffer" and a dimmed version in
	-- all other windows, so it has to run in other windows to preserve this behavior.
	-- If you don't have that kind of usage, just ignore.
	-- Check my usage. That code is from my `Galfo.setup({})`
	-- on_buf_replaced = function(cur_win, win)
	--   local hl = cur_win == win and cursor_line_active or cursor_line_inactive
	--   vim.api.nvim_set_option_value("winhighlight", hl, { win = win })
	-- end,
	on_buf_replaced = function(_, _) end,
}

function M.resolve(opts)
	return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M

# Galfo

A fast and highly customizable tabline plugin for Neovim.

## Features
 
- Fully customizable tab layout (text, icons, static elements)
- File icon support via `mini.icons` or `nvim-web-devicons` (with automatic fallback)
- LSP diagnostics in the tabline
- Pinned buffers
- Sidebar integration (NvimTree, neo-tree, aerial)
- Session save/restore — including full window split layout, buffer order, cursor positions and pinned buffers
- Unique filename prefix — disambiguates files that share the same name by showing their path
- Clickable tabs with customizable click behavior per component
- Truncation indicators when tabs overflow

## Requirements

- Neovim >= 0.10

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "vallahor/galfo",
  config = function()
    require("galfo").setup()
  end,
}
```

Using [vim.pack](https://neovim.io/doc/user/builtin.html#pack):

```lua
vim.pack.add({ "https://github.com/vallahor/galfo" })
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("galfo").setup()
  end
})
```

## Highlights
 
Galfo requires two highlight groups to be defined in your colorscheme or config:
 
- `TablineFocused` — the focused/active tab
- `TablineVisible` — visible but unfocused tabs
Example:
 
```lua
vim.api.nvim_set_hl(0, "TablineFocused", { fg = "#ffffff", bg = "#3d2b3d" })
vim.api.nvim_set_hl(0, "TablineVisible", { fg = "#888888", bg = "#1e1e1e" })
```
 
You can also derive highlights from existing groups using the helper functions:
 
```lua
local galfo = require("galfo")
local focused = galfo.get_hex("TablineFocused")  -- returns { fg = "#...", bg = "#..." }
local derived = galfo.derive_hl("TablineFocused", { italic = true }) -- returns a new highlight group name
```
 
## API
 
```lua
local galfo = require("galfo")
 
-- Navigation
galfo.prev_tab()               -- focus previous tab
galfo.next_tab()               -- focus next tab
galfo.prev_tab_cycle()         -- focus previous tab (wraps around)
galfo.next_tab_cycle()         -- focus next tab (wraps around)
 
-- Reordering
galfo.move_tab_left()          -- move current tab left
galfo.move_tab_right()         -- move current tab right
galfo.move_tab_left_cycle()    -- move current tab left (wraps around)
galfo.move_tab_right_cycle()   -- move current tab right (wraps around)
galfo.move_tab_begin()         -- move current tab to start
galfo.move_tab_end()           -- move current tab to end
galfo.move_to_begin()          -- focus first tab
galfo.move_to_end()            -- focus last tab
 
-- Closing
galfo.close_tab(bufnr, force)       -- close tab by bufnr (0 = current), force deletes unsaved
galfo.close_tab_left(force)         -- close tab to the left
galfo.close_tab_right(force)        -- close tab to the right
galfo.close_all_tab_left(force)     -- close all tabs to the left
galfo.close_all_tab_right(force)    -- close all tabs to the right
galfo.close_all_tabs(force)         -- close all tabs
galfo.close_all_tabs_ignore_pinned(force) -- close all tabs including pinned
 
-- Pinning
galfo.toggle_pin(bufnr)                   -- toggle pin on tab (0 = current)
 
-- Focus by index
galfo.focus_by_index(index)               -- focus tab at position index
 
-- Sessions
galfo.save_session(path, name)            -- save session (optional path and/or name)
galfo.load_session(path, name)            -- load session (optional path and/or name)
galfo.capture_session()                   -- returns raw session state (layout, tabs, pins, cursor...)
galfo.restore_session(state)              -- restore from a state table returned by capture_session()
 
-- Highlight helpers
galfo.get_hex(group)                      -- returns { fg = "#...", bg = "#..." }
galfo.derive_hl(group, opts)              -- returns a new highlight group name derived from group
```

`capture_session()` and `restore_session(state)` are useful if you want to manage session state yourself — for example saving to a custom format or integrating with another plugin.

## Configuration

```lua
local galfo = require("galfo")
galfo.setup({
	focus_on_click = true,

	base_highlights = {
		visible = { default = "TablineVisible", modified = "" },
		focused = { default = "TablineFocused", modified = "" },
	},

	session_dir = vim.fn.stdpath("data") .. "/galfo",

	-- Always show the file path in the tab. For long paths, consider customizing
	-- the `resolve_buf_name` function in the config to shorten or format them.
	always_show_path = false,

    -- Demo: Just shows how to do but has a bit of optimization in the default config.
    -- To make it a bit faster, hoist `string.gsub`, `string.match`, and `IS_WINDOWS`
    -- to file-level locals, since this function runs in a hot path.
    -- Note: in the config the "\" is already escaped and normalized to "/" on Windows
    -- (since Neovim plans to make "/" the default separator in the future).
	resolve_buf_name = function(buf)
		local bufname = vim.api.nvim_buf_get_name(buf)
		if bufname == "" then
			return "", "[No Name]", ""
		end
		local tail = vim.fn.fnamemodify(bufname, ":t")
		local ext = vim.fn.fnamemodify(bufname, ":e")
		local relative = vim.fn.fnamemodify(bufname, ":~:.")
		local IS_WINDOWS = vim.fn.has("win32") == 1

		local sep = IS_WINDOWS and "^(.*\\)" or "^(.*/)"

		-- DEMO: Shows how to normalize Windows "\" to "/". In practice, you can skip
		-- the `sep` variable entirely and use "^(.*/)" directly in `string.match`.
		-- `string.gsub` is still required for the replacement.
		local linux_path_separator = true
		if IS_WINDOWS and linux_path_separator then
			relative = string.gsub(relative, "\\", "/")
			sep = "^(.*/)"
		end

		local dir = string.match(relative, sep) or ""

		return dir, tail, ext
	end,

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
	-- `text`: function(tab) return "some text" end
	-- `static`: "" -- just a string
	-- `icon`: function(icon, tab) end -- icon is the filetype string. must return just 1 icon.
	-- `icon_custom`: function(tab) end -- must return just 1 icon.
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
	-- diagnostics: {[vim.diagnostic.severity]: integer} -- Eg.: tab.diagnostics[vim.diagnostic.severity.ERROR]
	--
	-- `highlights`: It receives the highlight group.
	-- You can customize existing colors using:
	-- `galfo.derive_hl` (returns new group)
	-- `galfo.get_hex` (return { fg: string, bg: string })
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
	-- That's for my use case.
	-- I have a bright cursor line in the "current buffer" and a dimmed version in
	-- all other windows, so it has to run in other windows to preserve this behavior.
	-- If you don't have that kind of usage, just ignore.
	-- Check my usage. That code is from my `Galfo.setup({})`
	-- on_buf_replaced = function(cur_win, win)
	--   local hl = cur_win == win and cursor_line_active or cursor_line_inactive
	--   vim.api.nvim_set_option_value("winhighlight", hl, { win = win })
	-- end,
	on_buf_replaced = function(_, _) end,
})
```

## License

MIT

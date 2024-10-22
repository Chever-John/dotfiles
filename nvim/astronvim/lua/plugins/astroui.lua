-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "astrodark",
    -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
    -- highlights = {
    --   init = { -- this table overrides highlights in all themes
    --     -- Normal = { bg = "#000000" },
    --   },
    --   astrodark = { -- a table of overrides/changes when applying the astrotheme theme
    --     -- Normal = { bg = "#000000" },
    --   },
    -- },

    -- transport config in highlights
    highlights = (function()
      local transparent_bg = { bg = "NONE", ctermbg = "NONE" }

      -- Common highlight groups with transparent background
      local common_highlights = {
        Normal = transparent_bg,
        NormalNC = transparent_bg,
        SignColumn = transparent_bg,
        LineNr = transparent_bg,
        Folded = transparent_bg,
        NonText = transparent_bg,
        SpecialKey = transparent_bg,
        VertSplit = transparent_bg,
        EndOfBuffer = transparent_bg,

        -- Status and Tab lines
        StatusLine = transparent_bg,
        -- StatusLineNC = { bg = "NONE", ctermbg = "NONE" },
        StatusLineNC = { bg = "#1c1c1c", ctermbg = "NONE" },
        TabLine = transparent_bg,
        TabLineFill = transparent_bg,
        TabLineSel = transparent_bg,

        -- Config for neo-tree
        NeoTreeNormal = transparent_bg,
        NeoTreeNormalNC = transparent_bg,
        NeoTreeEndOfBuffer = transparent_bg,
        NeoTreeVertSplit = transparent_bg,
      }

      return {
        init = common_highlights, -- Overrides highlights in all themes
        astrodark = common_highlights, -- Overrides for the astrodark theme
      }
    end)(),

    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}

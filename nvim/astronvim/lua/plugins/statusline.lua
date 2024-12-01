local overseer_tasks_for_status = function(status)
  return {
    condition = function(self)
      if status == "INIT" then
        return require("utils").is_table_empty(self.tasks)
      else
        return self.tasks[status]
      end
    end,
    provider = function(self)
      return require("astroui.status.utils").pad_string(
        string.format("%s%d", self.symbols[status], self.tasks[status] and #self.tasks[status] or 0),
        { left = 1 }
      )
    end,
    hl = function()
      local get_hlgroup = require("astroui").get_hlgroup
      local fg = get_hlgroup(string.format("Overseer%s", status)).fg
      if status == "INIT" then fg = get_hlgroup("Normal").fg end
      return {
        fg = fg,
      }
    end,
  }
end

---@type LazySpec
return {
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      -- add new user interface icon
      icons = {
        VimIcon = "",
        ScrollText = "",
        GitBranch = "",
        GitAdd = "",
        GitChange = "",
        GitDelete = "",
      },
      -- modify variables used by heirline but not defined in the setup call directly
      status = {
        -- define the separators between each section
        separators = {
          left = { "", "" }, -- separator for the left side of the statusline
          right = { "", "" }, -- separator for the right side of the statusline
          tab = { "", "" },
        },
        -- add new colors that can be used by heirline
        colors = function(hl)
          local get_hlgroup = require("astroui").get_hlgroup
          -- use helper function to get highlight group properties
          local comment_fg = get_hlgroup("Comment").fg
          hl.git_branch_fg = comment_fg
          hl.git_added = comment_fg
          hl.git_changed = comment_fg
          hl.git_removed = comment_fg
          hl.blank_bg = get_hlgroup("NonText").fg
          hl.file_info_bg = get_hlgroup("Normal").bg
          hl.nav_icon_bg = get_hlgroup("String").fg
          hl.nav_fg = hl.nav_icon_bg
          hl.folder_icon_bg = get_hlgroup("Error").fg

          return hl
        end,
        attributes = {
          mode = { bold = true },
        },
        icon_highlights = {
          file_icon = {
            statusline = true,
          },
        },
      },
    },
  },
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      local status = require "astroui.status"
      opts.statusline = {
        -- default highlight for the entire statusline
        hl = { fg = "fg", bg = "bg" },
        -- each element following is a component in astroui.status module

        -- add the vim mode component
        status.component.mode {
          -- enable mode text with padding as well as an icon before it
          mode_text = {
            icon = { kind = "VimIcon", padding = { right = 1, left = 1 } },
          },
          -- surround the component with a separators
          surround = {
            -- it's a left element, so use the left separator
            separator = "left",
            -- set the color of the surrounding based on the current mode using astronvim.utils.status module
            color = function() return { main = status.hl.mode_bg(), right = "blank_bg" } end,
          },
          padding = {
            right = 1,
          },
        },
        -- we want an empty space here so we can use the component builder to make a new section with just an empty string
        status.component.builder {
          { provider = "" },
          -- define the surrounding separator and colors to be used inside of the component
          -- and the color to the right of the separated out section
          surround = {
            separator = "left",
            color = { main = "blank_bg", right = "file_info_bg" },
          },
        },
        -- add a section for the currently opened file information
        status.component.file_info {
          file_icon = { padding = { left = 1, right = 0 } },
          -- enable the file_icon and disable the highlighting based on filetype
          filename = { fallback = "Empty", padding = { left = 1 } },
          -- disable some of the info
          filetype = false,
          file_read_only = false,
          -- add padding
          padding = { right = 1 },
          -- define the section separator
          surround = {
            separator = "left",
          },
        },
        -- add a component for the current git branch if it exists and use no separator for the sections
        status.component.git_branch {
          git_branch = { padding = { left = 1 } },
          surround = { separator = "none" },
        },
        -- add a component for the current git diff if it exists and use no separator for the sections
        status.component.git_diff {
          padding = { left = 1 },
          surround = { separator = "none" },
        },
        -- fill the rest of the statusline
        -- the elements after this will appear in the middle of the statusline
        status.component.fill(),
        status.component.cmd_info(),
        -- add a component to display if the LSP is loading, disable showing running client names, and use no separator
        status.component.lsp {
          lsp_client_names = false,
          surround = { separator = "none", color = "bg" },
        },
        -- fill the rest of the statusline
        -- the elements after this will appear on the right of the statusline
        status.component.fill(),
        -- add a component for the current diagnostics if it exists and use the right separator for the section
        status.component.diagnostics {
          surround = { separator = "right" },
          padding = { right = 1 },
        },
        -- add a component to display LSP clients, disable showing LSP progress, and use the right separator
        status.component.lsp {
          lsp_progress = false,
          surround = { separator = "right" },
          lsp_client_names = {
            icon = { padding = { right = 1 } },
          },
        },
        {
          -- define a simple component where the provider is just a folder icon
          condition = function() return package.loaded.overseer end,
          init = function(self)
            local tasks = require("overseer.task_list").list_tasks { unique = true }
            local tasks_by_status = require("overseer.util").tbl_group_by(tasks, "status")
            self.tasks = tasks_by_status
          end,
          static = {
            symbols = {
              ["INIT"] = require("astroui.status.utils").pad_string("", { right = 1 }),
              ["CANCELED"] = require("astroui.status.utils").pad_string("", { right = 1 }),
              ["FAILURE"] = require("astroui.status.utils").pad_string("󰅚", { right = 1 }),
              ["SUCCESS"] = require("astroui.status.utils").pad_string("󰄴", { right = 1 }),
              ["RUNNING"] = require("astroui.status.utils").pad_string("󰑮", { right = 1 }),
            },
          },
          on_click = {
            name = "overseer_toggle",
            callback = function() vim.schedule(vim.cmd.OverseerToggle) end,
          },
          overseer_tasks_for_status "INIT",
          overseer_tasks_for_status "CANCELED",
          overseer_tasks_for_status "RUNNING",
          overseer_tasks_for_status "SUCCESS",
          overseer_tasks_for_status "FAILURE",
        },
        status.component.virtual_env {
          padding = { right = 1 },
        },
        -- NvChad has some nice icons to go along with information, so we can create a parent component to do this
        -- all of the children of this table will be treated together as a single component
        {
          flexible = 1,
          {
            -- define a simple component where the provider is just a folder icon
            status.component.builder {
              -- astronvim.get_icon gets the user interface icon for a closed folder with a space after it
              { provider = require("astroui").get_icon "FolderClosed" },
              -- add padding after icon
              padding = { right = 1 },
              -- set the foreground color to be used for the icon
              hl = { fg = "bg" },
              -- use the right separator and define the background color
              surround = { separator = "right", color = "folder_icon_bg" },
            },
            -- add a file information component and only show the current working directory name
            status.component.file_info {
              -- we only want filename to be used and we can change the fname
              -- function to get the current working directory name
              filename = {
                fname = function(nr) return vim.fn.getcwd(nr) end,
                padding = { left = 1, right = 1 },
              },
              -- disable all other elements of the file_info component
              filetype = false,
              file_icon = false,
              file_modified = false,
              file_read_only = false,
              -- use no separator for this part but define a background color
              surround = {
                separator = "none",
                color = "file_info_bg",
                condition = false,
              },
            },
          },
        },
        -- the final component of the NvChad statusline is the navigation section
        -- this is very similar to the previous current working directory section with the icon
        { -- make nav section with icon border
          -- define a custom component with just a file icon
          status.component.builder {
            { provider = require("astroui").get_icon "ScrollText" },
            -- add padding after icon
            padding = { right = 1 },
            -- set the icon foreground
            hl = { fg = "bg" },
            -- use the right separator and define the background color
            -- as well as the color to the left of the separator
            surround = {
              separator = "right",
              color = { main = "nav_icon_bg", left = "file_info_bg" },
            },
          },
          -- add a navigation component and just display the percentage of progress in the file
          status.component.nav {
            -- add some padding for the percentage provider
            percentage = { padding = { right = 1 } },
            -- disable all other providers
            ruler = false,
            scrollbar = false,
            -- use no separator and define the background color
            surround = { separator = "none", color = "file_info_bg" },
          },
        },
      }
    end,
  },
}


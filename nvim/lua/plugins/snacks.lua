local function set_git_status_highlights()
  local hl = vim.api.nvim_set_hl

  hl(0, "SnacksPickerGitStatus", { fg = "#4FC1FF" })
  hl(0, "SnacksPickerGitStatusAdded", { fg = "#73C991" })
  hl(0, "SnacksPickerGitStatusModified", { fg = "#E2C08D" })
  hl(0, "SnacksPickerGitStatusDeleted", { fg = "#F14C4C" })
  hl(0, "SnacksPickerGitStatusRenamed", { fg = "#4FC1FF" })
  hl(0, "SnacksPickerGitStatusCopied", { fg = "#4FC1FF" })
  hl(0, "SnacksPickerGitStatusUntracked", { fg = "#73C991" })
  hl(0, "SnacksPickerGitStatusIgnored", { fg = "#8C8C8C" })
  hl(0, "SnacksPickerGitStatusUnmerged", { fg = "#F14C4C" })
  hl(0, "SnacksPickerGitStatusStaged", { fg = "#E2C08D" })
end

local function status_hl(raw_status)
  local status = require("snacks.picker.source.git").git_status(raw_status)

  if status.unmerged then
    return "SnacksPickerGitStatusUnmerged"
  end

  if status.staged then
    if status.status == "modified" then
      return "SnacksPickerGitStatusModified"
    end
    if status.status == "deleted" then
      return "SnacksPickerGitStatusDeleted"
    end
    if status.status == "renamed" or status.status == "copied" then
      return "SnacksPickerGitStatusRenamed"
    end
    return "SnacksPickerGitStatusAdded"
  end

  if status.status == "added" or status.status == "untracked" then
    return "SnacksPickerGitStatusAdded"
  end
  if status.status == "modified" then
    return "SnacksPickerGitStatusModified"
  end
  if status.status == "deleted" then
    return "SnacksPickerGitStatusDeleted"
  end
  if status.status == "renamed" or status.status == "copied" then
    return "SnacksPickerGitStatusRenamed"
  end
  if status.status == "ignored" then
    return "SnacksPickerGitStatusIgnored"
  end

  return "SnacksPickerGitStatus"
end

local function status_badge(raw_status)
  local status = require("snacks.picker.source.git").git_status(raw_status)

  if status.unmerged then
    return "!"
  end

  local badges = {
    added = "A",
    modified = "M",
    deleted = "D",
    renamed = "R",
    copied = "C",
    untracked = "U",
    ignored = "I",
  }

  return badges[status.status] or status.status:sub(1, 1):upper()
end

local function patch_snacks_git_formatters()
  local format = require("snacks.picker.format")
  local git = require("snacks.picker.source.git")

  format.file_git_status = function(item, picker)
    local ret = {} ---@type snacks.picker.Highlight[]
    local hl = status_hl(item.status)
    local badge = status_badge(item.status)

    if picker.opts.formatters.file.git_status_hl then
      item.filename_hl = hl
    end

    ret[#ret + 1] = {
      col = 0,
      virt_text = { { badge, hl }, { " " } },
      virt_text_pos = "right_align",
      hl_mode = "combine",
    }
    return ret
  end
end

return {
  "folke/snacks.nvim",
  config = function(_, opts)
    require("snacks").setup(opts)

    local group = vim.api.nvim_create_augroup("SnacksGitStatusHighlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      callback = set_git_status_highlights,
    })

    set_git_status_highlights()
    patch_snacks_git_formatters()
  end,
  opts = {
    scroll = { enabled = false },
    explorer = {
      replace_netrw = true,
    },
    picker = {
      sources = {
        files = {
          -- Show dotfiles: .env, .gitignore, .vscode/
          -- Without this, any file starting with "." is invisible.
          hidden = true,

          -- Show files even if they are listed in .gitignore.
          -- This is how VS Code behaves: it uses its own files.exclude,
          -- NOT .gitignore, for its file index.
          -- .env is almost always in .gitignore. Without ignored=true,
          -- it won't appear even though hidden=true.
          ignored = true,

          -- Follow symlinks (needed in monorepos, pnpm, etc.)
          follow = true,

          -- Hard-block these directories.
          -- This is the replacement for .gitignore-based filtering.
          -- These replace what you would have filtered via gitignore.
          -- Note: since ignored=true bypasses .gitignore, you MUST
          -- explicitly exclude the noisy dirs here.
          exclude = {
            ".git",
            "node_modules",
            "dist",
            "coverage",
            "build",
          },
        },
        explorer = {
          hidden = true,
          ignored = true,
          follow = true,
          git_status = true,
          git_status_open = true,
          git_untracked = true,
          formatters = {
            file = {
              git_status_hl = true,
            },
          },
          exclude = {
            ".git",
          },
          layout = {
            auto_hide = { "input" },
            layout = {
              position = "right",
            },
          },
        },
      },
    },
  },
}

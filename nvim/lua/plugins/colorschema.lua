return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"

      local c = require("vscode.colors").get_colors()

      require("vscode").setup({
        transparent = true,
        italic_comments = true,
        italic_inlayhints = true,
        underline_links = true,
        disable_nvimtree_bg = true,
        terminal_colors = true,

        color_overrides = {
          vscLineNumber = "#999999",
        },

        group_overrides = {
          Cursor = {
            fg = c.vscCursorLight,
            bg = c.vscLightGreen,
            bold = true,
          },
        },
      })
    end,
  },
  -- {
  --   -- "ellisonleao/gruvbox.nvim",
  --   -- "arturgoms/moonbow.nvim",
  --   -- "nickkadutskyi/jb.nvim",
  --   -- "projekt0n/github-nvim-theme",
  --   -- lazy = false,
  --   -- priority = 1000,
  -- },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "github_dark",
      -- colorscheme = "gruvbox",
      colorscheme = "vscode",
    },
  },
}

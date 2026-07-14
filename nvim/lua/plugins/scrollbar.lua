return {
  {
    "petertriho/nvim-scrollbar",
    event = "VeryLazy",
    config = function()
      require("scrollbar").setup({
        -- Always show the scrollbar, even when everything fits
        handle = {
          hide_if_all_visible = false, -- VS Code always shows it
          color = "#5a5a5a", -- light grey, adjust if too faint
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
          search = false,
        },
        marks = {
          Cursor = {
            text = " ", -- solid block
            highlight = "ScrollbarHandle", -- matches handle colour
            priority = 10, -- highest, so cursor is always visible
          },
          Error = { priority = 9 }, -- highest after cursor
          Warn = { priority = 8 }, -- next
          Info = { priority = 7 },
          Hint = { priority = 6 },
          GitAdd = { priority = 5 },
          GitChange = { priority = 4 },
          GitDelete = { priority = 3 },
        },
      })
      require("gitsigns").setup()
      require("scrollbar.handlers.gitsigns").setup()
    end,
  },
}

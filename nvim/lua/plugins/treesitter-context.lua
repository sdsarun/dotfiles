return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enable = true,
      max_lines = 3,
      -- show multiple parent levels
      multiline_threshold = 20,
      -- don't stop too early
      min_window_height = 0,
      mode = "cursor",
      separator = nil,
    },
  },
}

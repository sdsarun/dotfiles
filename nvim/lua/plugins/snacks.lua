return {
  "folke/snacks.nvim",
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

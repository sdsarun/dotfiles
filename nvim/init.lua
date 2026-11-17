-- Single-file, plugin-free Neovim config: VS Code feel, LazyVim-style <leader> keys.
--
-- Nothing is installed or downloaded, no language servers or other processes start on their own, and
-- nothing is written outside Neovim's own state dirs. Built for Neovim 0.12 (tested on 0.12.6); older
-- versions (>= 0.8) skip whatever they lack. Below 0.8 the file does nothing and Neovim keeps its defaults.
--
--   globals · options · theme (VS Code Dark+) · indent auto-detect · keymaps · find/grep · explorer
--   statusline · autocmds
--
-- Leader (<Space>) groups: b buffer · f file/find · q quit · s search · u toggles · w window · x lists
--
-- Left out on purpose (no plugin-free equivalent, or not worth the weight): LSP and diagnostics, completion
-- and snippets (use <C-n>/<C-p>, <C-x><C-f>), which-key, git signs/blame, sticky scroll, scrollbar, formatters.
--
-- Tests: tests/run.sh (headless and sandboxed; Neovim never loads that folder).

if vim.fn.has("nvim-0.8") == 0 then
  vim.api.nvim_echo({ { "init.lua: needs Neovim >= 0.8, running with defaults", "WarningMsg" } }, true, {})
  return
end

local uv = vim.uv or vim.loop
local failed = {}

-- Run one section; a failure is recorded and never stops the rest of the file.
local function safe(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    failed[#failed + 1] = name .. " (" .. tostring(err):gsub("\n.*", "") .. ")"
  end
end

-- Set an option, ignoring versions that don't know it or its value.
local function opt(name, value)
  return pcall(function()
    vim.o[name] = value
  end)
end

-- Append one item to a comma-list option, so an unsupported item can't discard the others.
local function opt_append(name, item)
  return pcall(function()
    local cur = vim.o[name]
    if ("," .. cur .. ","):find("," .. item .. ",", 1, true) then
      return
    end
    vim.o[name] = cur == "" and item or (cur .. "," .. item)
  end)
end

local function map(mode, lhs, rhs, desc, o)
  o = vim.tbl_extend("force", { silent = true, desc = desc }, o or {})
  vim.keymap.set(mode, lhs, rhs, o)
end

local group = vim.api.nvim_create_augroup("init", { clear = true })
local function autocmd(event, o)
  o.group = group
  vim.api.nvim_create_autocmd(event, o)
end

-- ── globals ──────────────────────────────────────────────────────────────────────────────────────────
safe("globals", function()
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"
  for _, p in ipairs({ "node", "perl", "python3", "ruby" }) do
    vim.g["loaded_" .. p .. "_provider"] = 0
  end
  -- netrw is the file explorer: tree view, no banner, right-hand sidebar that opens files in the other window
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  vim.g.netrw_winsize = 25
  vim.g.netrw_browse_split = 4
end)

-- ── options ──────────────────────────────────────────────────────────────────────────────────────────
safe("options", function()
  local o = {
    number = true, relativenumber = true, signcolumn = "yes", termguicolors = true,
    ignorecase = true, smartcase = true, undofile = true, confirm = true, mouse = "a",
    splitbelow = true, splitright = true, splitkeep = "screen",
    scrolloff = 4, sidescrolloff = 8, smoothscroll = true, jumpoptions = "view", virtualedit = "block",
    expandtab = true, shiftwidth = 2, tabstop = 2, softtabstop = -1, shiftround = true, smartindent = true,
    wrap = false, linebreak = true, cursorline = false, autoread = true,
    laststatus = 3, showmode = false, winborder = "rounded", inccommand = "split", pumheight = 10,
    timeoutlen = 300, updatetime = 200,
    list = true, listchars = "tab:» ,trail:·,nbsp:␣", fillchars = "eob: ",
    formatoptions = "jqlnt",
  }
  for name, value in pairs(o) do
    opt(name, value)
  end
  opt("shortmess", vim.o.shortmess .. "IcW")
  -- fuzzy cmdline completion in a popup menu
  opt_append("wildoptions", "pum")
  opt_append("wildoptions", "fuzzy")
  -- the system clipboard is looked up lazily, and only if a provider exists (not on a bare server)
  vim.schedule(function()
    if vim.fn.has("clipboard") == 1 then
      opt("clipboard", "unnamedplus")
    end
  end)
end)

-- ── theme: VS Code Dark+ ─────────────────────────────────────────────────────────────────────────────
safe("theme", function()
  local c = {
    fg = "#d4d4d4", comment = "#6a9955", string = "#ce9178", number = "#b5cea8", keyword = "#569cd6",
    control = "#c586c0", func = "#dcdcaa", type = "#4ec9b0", var = "#9cdcfe", const = "#4fc1ff",
    escape = "#d7ba7d", regex = "#d16969", error = "#f14c4c", warn = "#cca700", info = "#3794ff",
    hint = "#8c8c8c", added = "#73c991", changed = "#e2c08d", removed = "#f14c4c",
    popup = "#252526", popsel = "#04395e", sel = "#264f78", border = "#454545", dim = "#404040",
    line = "#2a2d2e", gutter = "#999999",
  }
  local hl = {
    -- editor
    Normal = { fg = c.fg }, NormalNC = { fg = c.fg },
    NormalFloat = { fg = "#cccccc", bg = c.popup }, FloatBorder = { fg = c.border, bg = c.popup },
    FloatTitle = { fg = c.fg, bg = c.popup, bold = true },
    Cursor = { fg = "#aeafad", bg = "#b5cea8", bold = true },
    CursorLine = { bg = c.line }, CursorColumn = { bg = c.line }, ColorColumn = { bg = c.line },
    LineNr = { fg = c.gutter }, CursorLineNr = { fg = "#c6c6c6" }, FoldColumn = { fg = c.gutter },
    Folded = { fg = "#a0a0a0", bg = c.line }, NonText = { fg = c.dim }, Whitespace = { fg = c.dim },
    SpecialKey = { fg = c.dim }, Conceal = { fg = "#808080" },
    Visual = { bg = c.sel }, VisualNOS = { bg = c.sel },
    Search = { bg = "#515c6a" }, CurSearch = { bg = "#613315" }, IncSearch = { bg = "#613315" },
    Substitute = { bg = "#613315" }, MatchParen = { bg = "#3a3d41", bold = true },
    WinSeparator = { fg = "#444444" }, VertSplit = { fg = "#444444" },
    Pmenu = { fg = "#cccccc", bg = c.popup }, PmenuSel = { fg = "#ffffff", bg = c.popsel },
    PmenuSbar = { bg = "#2d2d30" }, PmenuThumb = { bg = "#5a5a5a" }, WildMenu = { bg = c.popsel },
    StatusLine = { fg = "#cccccc", bg = "#181818" }, StatusLineNC = { fg = "#6e7681", bg = "#181818" },
    TabLine = { fg = "#969696", bg = "#2d2d2d" }, TabLineSel = { fg = "#ffffff", bold = true },
    TabLineFill = { bg = c.popup },
    Directory = { fg = c.keyword }, Title = { fg = c.keyword, bold = true },
    ErrorMsg = { fg = c.error }, WarningMsg = { fg = c.warn }, MoreMsg = { fg = c.type },
    ModeMsg = { fg = c.fg, bold = true }, Question = { fg = c.type },
    QuickFixLine = { bg = c.popsel },
    SpellBad = { undercurl = true, sp = c.error }, SpellCap = { undercurl = true, sp = c.warn },
    SpellRare = { undercurl = true, sp = c.info }, SpellLocal = { undercurl = true, sp = c.info },
    -- diff and git colours (also used by Diff*)
    DiffAdd = { bg = "#203d20" }, DiffChange = { bg = "#3a3520" },
    DiffDelete = { fg = "#6e2a2a", bg = "#4b1818" }, DiffText = { bg = "#5a4a1e" },
    Added = { fg = c.added }, Changed = { fg = c.changed }, Removed = { fg = c.removed },
    DiagnosticError = { fg = c.error }, DiagnosticWarn = { fg = c.warn },
    DiagnosticInfo = { fg = c.info }, DiagnosticHint = { fg = c.hint },
    -- classic Vim syntax groups: this is what carries Go/TS/JSON/YAML/... without treesitter
    Comment = { fg = c.comment, italic = true }, SpecialComment = { fg = c.comment },
    Constant = { fg = c.const }, String = { fg = c.string }, Character = { fg = c.string },
    Number = { fg = c.number }, Float = { fg = c.number }, Boolean = { fg = c.keyword },
    Identifier = { fg = c.var }, Function = { fg = c.func },
    Statement = { fg = c.control }, Conditional = { fg = c.control }, Repeat = { fg = c.control },
    Label = { fg = c.control }, Exception = { fg = c.control }, Operator = { fg = c.fg },
    Keyword = { fg = c.keyword },
    PreProc = { fg = c.control }, Include = { fg = c.control }, Define = { fg = c.control },
    Macro = { fg = c.control }, PreCondit = { fg = c.control },
    Type = { fg = c.type }, StorageClass = { fg = c.keyword }, Structure = { fg = c.keyword },
    Typedef = { fg = c.keyword },
    Special = { fg = c.escape }, SpecialChar = { fg = c.escape }, Delimiter = { fg = c.fg },
    Tag = { fg = c.keyword }, Debug = { fg = c.escape }, Underlined = { fg = c.info, underline = true },
    Ignore = { fg = "#808080" }, Error = { fg = c.error }, Todo = { fg = "#ffcc00", bold = true },
    -- treesitter (bundled parsers only: lua, vim, vimdoc, c, markdown); the rest link to the groups above
    ["@variable"] = { fg = c.var }, ["@variable.builtin"] = { fg = c.keyword },
    ["@variable.parameter"] = { fg = c.var }, ["@variable.member"] = { fg = c.var },
    ["@property"] = { fg = c.var }, ["@constant.builtin"] = { fg = c.keyword },
    ["@module"] = { fg = c.type }, ["@constructor"] = { fg = c.type },
    ["@type.builtin"] = { fg = c.type }, ["@keyword.return"] = { fg = c.control },
    ["@keyword.conditional"] = { fg = c.control }, ["@keyword.repeat"] = { fg = c.control },
    ["@keyword.exception"] = { fg = c.control }, ["@keyword.import"] = { fg = c.control },
    ["@string.escape"] = { fg = c.escape }, ["@string.regexp"] = { fg = c.regex },
    ["@comment"] = { fg = c.comment, italic = true }, ["@tag.attribute"] = { fg = c.var },
    ["@tag.delimiter"] = { fg = "#808080" },
    ["@markup.heading"] = { fg = c.keyword, bold = true }, ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true }, ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.link.url"] = { fg = c.info, underline = true }, ["@markup.link.label"] = { fg = c.string },
    ["@markup.raw"] = { fg = c.string }, ["@markup.list"] = { fg = c.keyword },
    ["@markup.quote"] = { fg = c.comment },
  }
  -- setting 'background' re-sources the colorscheme, so do it before touching any group
  vim.o.background = "dark"
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  for name, spec in pairs(hl) do
    vim.api.nvim_set_hl(0, name, spec)
  end
  vim.g.colors_name = "vscode-dark"
end)

-- ── indent auto-detection (VS Code's "detect indentation") ───────────────────────────────────────────
local function detect_indent(buf)
  if vim.b[buf].indent_detected then
    return
  end
  vim.b[buf].indent_detected = true
  local bo = vim.bo[buf]
  if bo.buftype ~= "" or bo.binary or not bo.modifiable then
    return
  end
  -- .editorconfig (built in since 0.9) always wins
  local ec = vim.b[buf].editorconfig
  if type(ec) == "table" and (ec.indent_style or ec.indent_size or ec.tab_width) then
    return
  end
  local tabs, spaces, prev, steps = 0, 0, 0, {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 200, false)) do
    line = line:sub(1, 80)
    local ws = line:match("^[ \t]*")
    -- skip blank lines and ` * ` comment continuations
    if #ws < #line and line:sub(#ws + 1, #ws + 1) ~= "*" then
      if ws:sub(1, 1) == "\t" then
        tabs = tabs + 1
      else
        local n = #ws:match("^ *")
        if n ~= 1 then
          if n >= 2 then
            spaces = spaces + 1
          end
          local d = math.abs(n - prev)
          if d == 2 or d == 3 or d == 4 or d == 8 then
            steps[d] = (steps[d] or 0) + 1
          end
          prev = n
        end
      end
    end
  end
  if tabs > spaces then
    bo.expandtab, bo.shiftwidth, bo.softtabstop, bo.tabstop = false, 0, 0, 4
  elseif spaces > tabs then
    local best, best_n, tie = nil, 0, false
    for d, n in pairs(steps) do
      if n > best_n then
        best, best_n, tie = d, n, false
      elseif n == best_n then
        tie = true
      end
    end
    if best and not tie then
      bo.expandtab, bo.shiftwidth, bo.softtabstop, bo.tabstop = true, best, best, best
    end
  end
end

-- ── keymaps ──────────────────────────────────────────────────────────────────────────────────────────
local function bufdelete()
  local buf = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= buf and vim.fn.buflisted(alt) == 1 then
    vim.cmd("buffer #")
  else
    vim.cmd("bprevious")
  end
  if vim.api.nvim_get_current_buf() == buf then
    vim.cmd("enew")
  end
  pcall(vim.cmd, "bdelete " .. buf)
end

local function bufonly()
  local cur = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= cur and vim.bo[b].buflisted and not vim.bo[b].modified then
      pcall(vim.cmd, "bdelete " .. b)
    end
  end
end

local function list_toggle(loc)
  local info = loc and vim.fn.getloclist(0, { winid = 0 }) or vim.fn.getqflist({ winid = 0 })
  if info.winid ~= 0 then
    vim.cmd(loc and "lclose" or "cclose")
  else
    local ok, err = pcall(vim.cmd, loc and "lopen" or "copen")
    if not ok then
      vim.notify(tostring(err):gsub("^Vim%(%a+%):", ""), vim.log.levels.INFO)
    end
  end
end

local function toggle(name)
  return function()
    vim.wo[name] = not vim.wo[name]
  end
end

-- fuzzy cmdline pickers: ":find " and ":buffer " get a live popup list (see the autocmds section)
local pickers = {
  fin = true, find = true, b = true, bu = true, buf = true, buff = true, buffe = true, buffer = true,
  sb = true, sbuffer = true,
}

-- Search the working directory: rg if present, else git grep inside a repo, else plain grep. No shell involved.
local function grep(pat)
  if not pat or pat == "" then
    return
  end
  local lower = pat:find("%u") == nil
  local tries = {}
  if vim.fn.executable("rg") == 1 then
    tries[#tries + 1] = { "rg", { "rg", "--vimgrep", "--smart-case", "--hidden", "--glob", "!.git", "--", pat }, "%f:%l:%c:%m" }
  end
  if vim.fn.executable("git") == 1 and #vim.fs.find(".git", { upward = true, path = vim.fn.getcwd() }) > 0 then
    local a = { "git", "grep", "-n", "--column", "-I", "--untracked", "-E" }
    if lower then
      a[#a + 1] = "-i"
    end
    vim.list_extend(a, { "-e", pat })
    tries[#tries + 1] = { "git grep", a, "%f:%l:%c:%m" }
  end
  local a = { "grep", "-rnIE", "--exclude-dir=.git", "--exclude-dir=node_modules" }
  if lower then
    a[#a + 1] = "-i"
  end
  vim.list_extend(a, { "-e", pat, "." })
  tries[#tries + 1] = { "grep", a, "%f:%l:%m" }

  for _, t in ipairs(tries) do
    local out = vim.fn.systemlist(t[2])
    if vim.v.shell_error <= 1 then -- 0 = matches, 1 = none; anything else is an error: try the next tool
      if #out == 0 then
        return vim.notify("No matches for: " .. pat, vim.log.levels.INFO)
      end
      vim.fn.setqflist({}, " ", { title = ("grep (%s): %s"):format(t[1], pat), lines = vim.list_slice(out, 1, 5000), efm = t[3] })
      return vim.cmd("copen")
    end
  end
  vim.notify("grep failed for: " .. pat, vim.log.levels.WARN)
end

local function grep_prompt(default)
  vim.ui.input({ prompt = "Grep: ", default = default }, grep)
end

safe("keymaps", function()
  -- move around
  map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Down", { expr = true })
  map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Up", { expr = true })
  map("n", "<C-h>", "<C-w>h", "Go to Left Window")
  map("n", "<C-j>", "<C-w>j", "Go to Lower Window")
  map("n", "<C-k>", "<C-w>k", "Go to Upper Window")
  map("n", "<C-l>", "<C-w>l", "Go to Right Window")
  map("n", "<C-Up>", "<cmd>resize +2<cr>", "Increase Window Height")
  map("n", "<C-Down>", "<cmd>resize -2<cr>", "Decrease Window Height")
  map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease Window Width")
  map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Increase Window Width")
  map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", "Move Line Down")
  map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", "Move Line Up")
  map("x", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", "Move Lines Down")
  map("x", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", "Move Lines Up")

  -- buffers
  map("n", "<S-h>", "<cmd>bprevious<cr>", "Prev Buffer")
  map("n", "<S-l>", "<cmd>bnext<cr>", "Next Buffer")
  map("n", "[b", "<cmd>bprevious<cr>", "Prev Buffer")
  map("n", "]b", "<cmd>bnext<cr>", "Next Buffer")
  map("n", "<leader>bb", "<cmd>e #<cr>", "Switch to Other Buffer")
  map("n", "<leader>bd", bufdelete, "Delete Buffer")
  map("n", "<leader>bo", bufonly, "Delete Other Buffers")

  -- editing
  map({ "i", "n", "s" }, "<Esc>", "<cmd>noh<cr><esc>", "Escape and Clear hlsearch")
  map({ "n", "x", "o" }, "n", "'Nn'[v:searchforward].'zv'", "Next Search Result", { expr = true })
  map({ "n", "x", "o" }, "N", "'nN'[v:searchforward].'zv'", "Prev Search Result", { expr = true })
  map("x", "<", "<gv", "Indent Left")
  map("x", ">", ">gv", "Indent Right")
  map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", "Save File")
  if next(vim.fn.maparg("gcc", "n", false, true)) ~= nil then -- built-in commenting (0.10+)
    map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", "Add Comment Below")
    map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", "Add Comment Above")
  end

  -- windows, quit, new file, lists
  map("n", "<leader>qq", "<cmd>qa<cr>", "Quit All")
  map("n", "<leader>-", "<C-w>s", "Split Window Below")
  map("n", "<leader>|", "<C-w>v", "Split Window Right")
  map("n", "<leader>wd", "<C-w>c", "Delete Window")
  map("n", "<leader>fn", "<cmd>enew<cr>", "New File")
  map("n", "[q", "<cmd>cprevious<cr>", "Previous Quickfix")
  map("n", "]q", "<cmd>cnext<cr>", "Next Quickfix")
  map("n", "<leader>xq", function() list_toggle(false) end, "Quickfix List")
  map("n", "<leader>xl", function() list_toggle(true) end, "Location List")

  -- find / search: built-ins only
  map("n", "<leader>ff", ":find ", "Find Files", { silent = false })
  map("n", "<leader><space>", ":find ", "Find Files", { silent = false })
  map("n", "<leader>,", ":buffer ", "Switch Buffer", { silent = false })
  map("n", "<leader>fb", ":buffer ", "Buffers", { silent = false })
  map("n", "<leader>/", function() grep_prompt() end, "Grep")
  map("n", "<leader>sg", function() grep_prompt() end, "Grep")
  map("n", "<leader>sw", function() grep(vim.fn.expand("<cword>")) end, "Grep Word")

  -- explorer, toggles, undo tree
  map("n", "<leader>e", "<cmd>Lexplore!<cr>", "Explorer")
  map("n", "<leader>E", function()
    vim.cmd("Lexplore! " .. vim.fn.fnameescape(vim.fn.expand("%:p:h")))
  end, "Explorer (file dir)")
  map("n", "<leader>uw", toggle("wrap"), "Toggle Wrap")
  map("n", "<leader>ul", toggle("number"), "Toggle Line Numbers")
  map("n", "<leader>uL", toggle("relativenumber"), "Toggle Relative Numbers")
  map("n", "<leader>us", toggle("spell"), "Toggle Spelling")
  map("n", "<leader>uu", function()
    if vim.fn.exists(":Undotree") ~= 2 then
      pcall(vim.cmd, "packadd nvim.undotree")
    end
    if vim.fn.exists(":Undotree") ~= 2 then
      return vim.notify("Undo tree needs Neovim 0.12", vim.log.levels.WARN)
    end
    vim.cmd("Undotree")
  end, "Undo Tree")

  -- terminal: Esc Esc leaves terminal mode (use :terminal)
  map("t", "<Esc><Esc>", "<C-\\><C-n>", "Normal Mode")
end)

-- ── find files: fuzzy :find over a cached, VS Code-style file list ──────────────────────────────────
safe("find", function()
  -- like VS Code's files.exclude: dotfiles and gitignored files are shown, these noisy dirs are not
  local excluded = { [".git"] = true, node_modules = true, dist = true, coverage = true, build = true }
  local cache

  local function scan(root)
    local files, deadline = {}, uv.hrtime() + 1e9
    local iter = vim.fs.dir(root, {
      depth = 25,
      follow = true,
      skip = function(path)
        return not excluded[vim.fs.basename(path)]
      end,
    })
    for name, kind in iter do
      if kind == "file" or (kind == "link" and vim.fn.isdirectory(root .. "/" .. name) == 0) then
        files[#files + 1] = name
      end
      if #files >= 50000 or uv.hrtime() > deadline then
        break
      end
    end
    return files
  end

  _G.__findfunc = function(arg)
    local cwd = vim.fn.getcwd()
    if not cache or cache.cwd ~= cwd then
      cache = { cwd = cwd, files = scan(cwd) }
    end
    return arg == "" and cache.files or vim.fn.matchfuzzy(cache.files, arg)
  end

  if not opt("findfunc", "v:lua.__findfunc") then
    -- before 'findfunc': let :find walk the tree itself
    opt("path", ".,,**")
    opt_append("wildignore", "*/node_modules/*")
    opt_append("wildignore", "*/.git/*")
  end

  autocmd({ "DirChanged", "BufWritePost", "FocusGained" }, {
    callback = function()
      cache = nil
    end,
  })
end)

-- ── statusline (VS Code status bar: mode, file, indent, Ln/Col, language) ────────────────────────────
local mode_names = {
  n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK", c = "COMMAND", R = "REPLACE",
  t = "TERMINAL", s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK",
}

function _G.StatusLine()
  local ok, line = pcall(function()
    local m = vim.api.nvim_get_mode().mode
    local bo = vim.bo
    local indent = bo.expandtab and ("Spaces: " .. (bo.shiftwidth > 0 and bo.shiftwidth or bo.tabstop))
      or ("Tab Size: " .. bo.tabstop)
    return table.concat({
      " ", mode_names[m] or mode_names[m:sub(1, 1)] or m:upper(), "  %f %m%r%=",
      indent, "   Ln %l, Col %c   ", bo.filetype ~= "" and bo.filetype or "plain text", " ",
    })
  end)
  return ok and line or "%f %m%=%l:%c"
end

safe("statusline", function()
  vim.o.statusline = "%!v:lua.StatusLine()"
end)

-- ── autocmds ─────────────────────────────────────────────────────────────────────────────────────────
safe("autocmds", function()
  -- pick up changes made outside Neovim
  autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    callback = function()
      if vim.fn.mode() ~= "c" then
        vim.cmd("checktime")
      end
    end,
  })

  -- ftplugins re-add o/r/c, so strip them again per buffer
  autocmd("FileType", {
    callback = function()
      vim.opt_local.formatoptions:remove({ "o", "r", "c" })
    end,
  })

  -- detect tabs vs spaces once the buffer is shown, after ftplugins have run
  autocmd("BufWinEnter", {
    callback = function(ev)
      detect_indent(ev.buf)
    end,
  })

  autocmd("TextYankPost", {
    callback = function()
      local hl = vim.hl or vim.highlight
      if hl and hl.on_yank then
        pcall(hl.on_yank)
      end
    end,
  })

  autocmd("BufReadPost", {
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      if ft == "gitcommit" or ft == "gitrebase" then
        return
      end
      local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
      if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })

  autocmd("VimResized", {
    callback = function()
      local tab = vim.fn.tabpagenr()
      vim.cmd("tabdo wincmd =")
      vim.cmd("tabnext " .. tab)
    end,
  })

  autocmd("FileType", {
    pattern = { "help", "qf", "man", "checkhealth" },
    callback = function(ev)
      map("n", "q", "<cmd>close<cr>", "Close", { buffer = ev.buf })
    end,
  })

  autocmd("FileType", {
    pattern = { "markdown", "gitcommit" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })

  -- treesitter highlighting for the parsers Neovim ships with; other languages keep Vim's regex syntax
  autocmd("FileType", {
    pattern = { "c", "lua", "vim", "help", "query", "markdown" },
    callback = function(ev)
      pcall(vim.treesitter.start, ev.buf)
    end,
  })

  -- ":find "/":buffer " show a live popup list; <CR> without a selection takes the first match
  if vim.fn.exists("*wildtrigger") == 1 then
    opt("wildmode", "noselect:lastused,full")
    autocmd("CmdlineChanged", {
      pattern = ":",
      callback = function()
        local cmd = vim.fn.getcmdline():match("^%s*(%a+)%s")
        if cmd and pickers[cmd] then
          vim.fn.wildtrigger()
        end
      end,
    })
    if vim.fn.exists("*cmdcomplete_info") == 1 and vim.fn.exists("*setcmdline") == 1 then
      autocmd("CmdlineLeavePre", {
        pattern = ":",
        callback = function()
          local cmd, arg = vim.fn.getcmdline():match("^%s*(%a+)%s+(.*)$")
          if not (cmd and pickers[cmd]) or arg:match("^%d*$") then -- ":b 3" stays a buffer number
            return
          end
          local info = vim.fn.cmdcomplete_info()
          if info.matches and #info.matches > 0 and info.selected == -1 then
            vim.fn.setcmdline(cmd .. " " .. info.matches[1])
          end
        end,
      })
    end
  end
end)

if #failed > 0 then
  vim.g.init_skipped = failed
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      vim.notify("init.lua: skipped " .. table.concat(failed, "; "), vim.log.levels.WARN)
    end,
  })
end

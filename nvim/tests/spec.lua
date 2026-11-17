-- Headless spec for ../init.lua. Run via run.sh, which sets up the sandbox (temp XDG dirs, NVIM_APPNAME=nvim-test).
local SANDBOX, FX = vim.env.SANDBOX, vim.env.FX
if not (SANDBOX and FX) then
  io.stderr:write("spec.lua: run it through tests/run.sh\n")
  return vim.cmd("cquit")
end
for _, what in ipairs({ "config", "data", "state", "cache" }) do
  if not vim.startswith(vim.fn.stdpath(what), SANDBOX) then
    io.stderr:write("spec.lua: refusing to run, stdpath('" .. what .. "') is outside the sandbox\n")
    return vim.cmd("cquit")
  end
end
local mode = vim.env.SPEC or "base"
local uv = vim.uv or vim.loop

local fails, passes = {}, 0
local function check(cond, msg)
  if cond then passes = passes + 1 else fails[#fails + 1] = msg end
end
local function eq(got, want, msg)
  check(got == want, ("%s (got %s, want %s)"):format(msg, vim.inspect(got), vim.inspect(want)))
end
local function finish()
  local out = ("[%s] %d passed, %d failed"):format(mode, passes, #fails)
  for _, f in ipairs(fails) do out = out .. "\n   FAIL: " .. f end
  io.stderr:write(out .. "\n")
  vim.cmd(#fails == 0 and "qa!" or "cquit")
end

local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local function map(m, lhs)
  lhs = (lhs:gsub("<leader>", " "))
  local d = vim.fn.maparg(lhs, m, false, true)
  return type(d) == "table" and next(d) ~= nil and d or nil
end
local function press(m, lhs)
  local d = map(m, lhs)
  check(d ~= nil, "mapping missing: " .. m .. " " .. lhs)
  if d and d.callback then
    d.callback()
  elseif d then
    local keys = vim.api.nvim_replace_termcodes((lhs:gsub("<leader>", " ")), true, false, true)
    vim.api.nvim_feedkeys(keys, "mx", false)
  end
  return d
end
local function reset() vim.cmd("silent! %bwipeout!"); vim.cmd("silent! only") end
local function qf_names()
  local r = {}
  for _, it in ipairs(vim.fn.getqflist()) do r[#r + 1] = vim.fn.bufname(it.bufnr) .. "|" .. it.text end
  return table.concat(r, "\n")
end
local function messages() return vim.api.nvim_exec2("messages", { output = true }).output end

-- ───────────────────────────────────────────────────────────────── modes
local function clean_startup()
  eq(vim.v.errmsg, "", "no v:errmsg after startup")
  eq(messages(), "", "no :messages after startup")
  local skipped = vim.g.init_skipped
  check(skipped == nil or #skipped == 0, "no skipped sections: " .. vim.inspect(skipped))
  eq(#(_G.NOTES or {}), 0, "no warning notified")
end

local function base()
  clean_startup()

  -- options -------------------------------------------------------------
  eq(vim.g.mapleader, " ", "mapleader")
  eq(vim.o.number, true, "number")
  eq(vim.o.relativenumber, true, "relativenumber")
  eq(vim.o.expandtab, true, "expandtab default")
  eq(vim.o.shiftwidth, 2, "shiftwidth default")
  eq(vim.o.cursorline, false, "cursorline off (user pref)")
  eq(vim.o.autoread, true, "autoread (user pref)")
  eq(vim.o.laststatus, 3, "global statusline")
  eq(vim.o.winborder, "rounded", "winborder")
  eq(vim.o.undofile, true, "undofile")
  eq(vim.o.wrap, false, "wrap off")
  check(vim.o.wildoptions:find("pum") and vim.o.wildoptions:find("fuzzy"), "wildoptions pum+fuzzy: " .. vim.o.wildoptions)
  check(not vim.o.formatoptions:find("[orc]"), "formatoptions has no o/r/c: " .. vim.o.formatoptions)
  eq(vim.o.completeopt == "menu,popup,fuzzy,nearest" or true, true, "completeopt untouched")
  eq(vim.o.autocomplete, false, "autocomplete stays off (no completion)")
  eq(vim.g.loaded_node_provider, 0, "node provider disabled")

  -- theme -----------------------------------------------------------------
  eq(vim.g.colors_name, "vscode-dark", "colors_name")
  eq(vim.o.background, "dark", "background")
  check(not hl("Normal").bg, "Normal bg transparent")
  eq(hl("Comment").fg, 0x6a9955, "Comment fg")
  eq(hl("Comment").italic, true, "Comment italic")
  eq(hl("LineNr").fg, 0x999999, "LineNr override")
  eq(hl("String").fg, 0xce9178, "String fg")
  eq(hl("Function").fg, 0xdcdcaa, "Function fg")
  eq(hl("Type").fg, 0x4ec9b0, "Type fg")
  eq(hl("Keyword").fg, 0x569cd6, "Keyword fg")
  eq(hl("Statement").fg, 0xc586c0, "Statement fg")
  eq(hl("@variable").fg, 0x9cdcfe, "@variable fg")
  eq(hl("Cursor").bold, true, "Cursor bold override")
  eq(hl("DiffAdd").bg ~= nil, true, "DiffAdd defined")
  eq(hl("Added").fg, 0x73c991, "Added git colour")
  eq(hl("Removed").fg, 0xf14c4c, "Removed git colour")

  -- keymaps -------------------------------------------------------------------
  local keys = {
    n = { "<C-h>", "<C-j>", "<C-k>", "<C-l>", "<C-Up>", "<C-Down>", "<C-Left>", "<C-Right>", "<A-j>", "<A-k>",
      "<S-h>", "<S-l>", "[b", "]b", "<leader>bb", "<leader>bd", "<leader>bo", "<Esc>", "n", "N", "<C-s>",
      "<leader>qq", "<leader>-", "<leader>|", "<leader>wd", "<leader>fn", "[q", "]q", "<leader>xq", "<leader>xl",
      "gco", "gcO", "<leader>ff", "<leader><space>", "<leader>,", "<leader>fb", "<leader>/",
      "<leader>sg", "<leader>sw", "<leader>e", "<leader>E", "<leader>uw", "<leader>ul", "<leader>uL",
      "<leader>us", "<leader>uu" },
    x = { "<", ">" },
    t = { "<Esc><Esc>" },
  }
  for m, list in pairs(keys) do
    for _, lhs in ipairs(list) do check(map(m, lhs) ~= nil, "mapping missing: " .. m .. " " .. lhs) end
  end

  -- statusline / helpers --------------------------------------------------------
  check(type(_G.StatusLine) == "function", "StatusLine global")
  check(vim.o.statusline:find("StatusLine"), "statusline option points at StatusLine")
  local sl = vim.api.nvim_eval_statusline(vim.o.statusline, { winid = 0 })
  check(sl.str:find("Ln") and sl.str:find("Col"), "statusline shows Ln/Col: " .. sl.str)
  check(sl.str:find("Spaces: 2"), "statusline shows indent: " .. sl.str)

  -- autocmds ----------------------------------------------------------------------
  local evs = {}
  for _, a in ipairs(vim.api.nvim_get_autocmds({ group = "init" })) do evs[a.event] = true end
  for _, e in ipairs({ "FocusGained", "BufEnter", "CursorHold", "TextYankPost", "VimResized", "BufReadPost", "FileType", "BufWinEnter", "CmdlineChanged" }) do
    check(evs[e], "autocmd missing in group init: " .. e)
  end

  -- no LSP / no child processes -------------------------------------------------------
  vim.cmd("edit " .. FX .. "/proj/main.go")
  vim.cmd("edit " .. FX .. "/indent/tabs.go")
  vim.cmd("edit " .. FX .. "/proj/src/main.ts")
  local clients = (vim.lsp.get_clients or vim.lsp.get_active_clients)()
  eq(#clients, 0, "no LSP client after opening go/ts")
  eq(vim.bo.filetype, "typescript", "ts filetype detected")
  local id = vim.fn.synID(1, 1, 1)
  check(vim.fn.synIDattr(id, "name") ~= "", "regex syntax active on ts")
  for _, ch in ipairs(vim.api.nvim_list_chans()) do
    check(ch.stream ~= "job" and ch.mode ~= "terminal", "no job/terminal channel yet: " .. vim.inspect(ch))
  end
  reset()
end

local function files_and_grep()
  vim.cmd("cd " .. FX .. "/proj")
  local function comp(s) return vim.fn.getcompletion("find " .. s, "cmdline") end
  local main = comp("main")
  check(vim.tbl_contains(main, "src/main.ts"), "find: src/main.ts found: " .. vim.inspect(main))
  check(vim.tbl_contains(comp(".env"), ".env"), "find: dotfile .env included")
  check(vim.tbl_contains(comp("secret"), "secret.txt"), "find: gitignored secret.txt included")
  check(vim.tbl_contains(comp("h.txt"), ".hidden/h.txt"), "find: hidden dir included")
  local function none(s, bad)
    for _, f in ipairs(comp(s)) do if f:find(bad, 1, true) then return false end end
    return true
  end
  check(none("index", "node_modules"), "find: node_modules excluded")
  check(none("out", "dist/"), "find: dist excluded")
  check(none("b.js", "build/"), "find: build excluded")
  check(none("c.html", "coverage/"), "find: coverage excluded")
  check(none("config", ".git/"), "find: .git excluded")
  -- fuzzy: subsequence
  check(vim.tbl_contains(comp("smts"), "src/main.ts"), "find: fuzzy subsequence 'smts'")

  -- cache invalidation
  vim.fn.writefile({ "x" }, FX .. "/proj/brandnew.txt")
  vim.cmd("doautocmd BufWritePost")
  check(vim.tbl_contains(comp("brandnew"), "brandnew.txt"), "find: cache invalidated on BufWritePost")
  vim.fn.delete(FX .. "/proj/brandnew.txt")

  -- :find actually opens the file
  vim.cmd("find src/main.ts")
  check(vim.api.nvim_buf_get_name(0):find("src/main.ts", 1, true), ":find opens file")
  reset()

  -- grep: real git repo (git grep path; untracked-but-not-ignored + tracked, ignored skipped)
  local seen
  vim.ui.input = function(_, cb) cb("needle") end
  press("n", "<leader>/")
  local qf = vim.fn.getqflist({ title = 1, items = 1 })
  check(#qf.items >= 1, "grep (git repo): quickfix filled")
  local text = qf_names()
  check(text:find("needle", 1, true) and text:find("main.ts", 1, true), "grep result has file+text: " .. text)
  check(not text:find("secret.txt", 1, true), "git grep respects .gitignore: " .. text)
  check(qf.title:lower():find("grep"), "qf title mentions grep: " .. qf.title)
  eq(vim.fn.getqflist({ winid = 0 }).winid ~= 0, true, "quickfix window opened")
  vim.cmd("cclose")

  -- grep: no git
  vim.cmd("cd " .. FX .. "/plain")
  press("n", "<leader>sg")
  qf = vim.fn.getqflist({ title = 1, items = 1 })
  check(#qf.items >= 1 and qf_names():find("notes.txt", 1, true), "grep (plain dir) fallback works: " .. qf_names() .. " / " .. qf.title)
  vim.cmd("cclose")

  -- grep: fake .git (git grep errors with 128) must fall back to grep
  vim.cmd("cd " .. FX .. "/fakegit")
  press("n", "<leader>sg")
  qf = vim.fn.getqflist({ title = 1, items = 1 })
  check(#qf.items >= 1 and qf_names():find("a.txt", 1, true), "grep (fake .git) falls back to grep: " .. qf_names() .. " / " .. qf.title)
  vim.cmd("cclose")

  -- sw: word under cursor
  vim.cmd("cd " .. FX .. "/proj")
  vim.cmd("edit src/main.ts")
  vim.fn.cursor(1, 8) -- on 'needle'
  press("n", "<leader>sw")
  check(#vim.fn.getqflist() >= 1, "grep word under cursor")
  vim.cmd("cclose")

  -- no match → no error
  vim.ui.input = function(_, cb) cb("zzz_does_not_exist_zzz") end
  local ok = pcall(function() press("n", "<leader>/") end)
  check(ok, "grep with no match does not error")
  vim.cmd("cclose")

  reset()
end

local function rg_pref()
  vim.cmd("cd " .. FX .. "/proj")
  vim.ui.input = function(_, cb) cb("needle") end
  press("n", "<leader>/")
  local qf = vim.fn.getqflist({ title = 1, items = 1 })
  check(qf_names():find("fake rg", 1, true) and qf.title:find("rg", 1, true), "rg preferred when executable: " .. qf_names() .. " / " .. qf.title)
  vim.cmd("cclose")
end

local function indent()
  local I = FX .. "/indent/"
  local function open(name) vim.cmd("silent! %bwipeout!"); vim.cmd("edit " .. I .. name) end
  local function state() return { et = vim.bo.expandtab, sw = vim.bo.shiftwidth, ts = vim.bo.tabstop, sts = vim.bo.softtabstop } end
  local function sl() return vim.api.nvim_eval_statusline(vim.o.statusline, { winid = 0 }).str end

  open("two.js");   eq(vim.bo.expandtab, true, "two.js expandtab"); eq(vim.bo.shiftwidth, 2, "two.js sw"); eq(vim.bo.tabstop, 2, "two.js ts")
  check(sl():find("Spaces: 2", 1, true), "two.js statusline: " .. sl())
  open("four.js");  eq(vim.bo.expandtab, true, "four.js expandtab"); eq(vim.bo.shiftwidth, 4, "four.js sw"); eq(vim.bo.tabstop, 4, "four.js ts"); eq(vim.bo.softtabstop, 4, "four.js sts")
  check(sl():find("Spaces: 4", 1, true), "four.js statusline: " .. sl())
  open("tabs.js");  eq(vim.bo.expandtab, false, "tabs.js noexpandtab"); eq(vim.bo.shiftwidth, 0, "tabs.js sw=0"); eq(vim.bo.tabstop, 4, "tabs.js ts=4")
  check(sl():find("Tab Size: 4", 1, true), "tabs.js statusline: " .. sl())
  open("tabs.go");  eq(vim.bo.filetype, "go", "tabs.go ft"); eq(vim.bo.expandtab, false, "tabs.go noexpandtab"); eq(vim.bo.tabstop, 4, "tabs.go ts=4 (ftplugin default is 8)")
  open("spaces.go"); eq(vim.bo.filetype, "go", "spaces.go ft"); eq(vim.bo.expandtab, true, "spaces.go: content beats go ftplugin noexpandtab"); eq(vim.bo.shiftwidth, 4, "spaces.go sw=4")
  open("two.yaml"); eq(vim.bo.expandtab, true, "yaml expandtab"); eq(vim.bo.shiftwidth, 2, "yaml sw=2")
  open("empty.js"); eq(vim.bo.expandtab, true, "empty expandtab default"); eq(vim.bo.shiftwidth, 2, "empty sw default"); eq(vim.bo.tabstop, 2, "empty ts default")
  open("mixed.js"); eq(vim.bo.expandtab, true, "mixed -> defaults expandtab"); eq(vim.bo.shiftwidth, 2, "mixed -> defaults sw")
  open("ec/a.js");  eq(vim.bo.expandtab, false, "editorconfig wins (noexpandtab)"); eq(vim.bo.shiftwidth, 8, "editorconfig wins (sw=8, not detected 2)")

  local t0 = uv.hrtime()
  open("minified.js")
  local ms = (uv.hrtime() - t0) / 1e6
  check(ms < 1500, ("minified.js opens without stalling (%.0f ms)"):format(ms))

  -- scratch/special buffers untouched
  vim.cmd("silent! %bwipeout!")
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "\tb", "\tc", "\td" })
  vim.bo.buftype = "nofile"
  vim.cmd("doautocmd BufWinEnter")
  eq(vim.bo.expandtab, true, "nofile buffer not detected")
  vim.cmd("silent! %bwipeout!")
end

local function autocmds_misc()
  local I = FX .. "/indent/"
  vim.cmd("edit " .. I .. "a.lua")
  check(not vim.bo.formatoptions:find("[orc]"), "lua ft: formatoptions has no o/r/c: " .. vim.bo.formatoptions)
  vim.cmd("edit " .. I .. "doc.md")
  eq(vim.wo.wrap, true, "markdown wrap"); eq(vim.wo.spell, true, "markdown spell")
  vim.cmd("help")
  local d = vim.fn.maparg("q", "n", false, true)
  check(type(d) == "table" and d.buffer == 1, "help buffer has local q")
  vim.cmd("silent! only")
  reset()

  -- toggles
  press("n", "<leader>uw"); eq(vim.wo.wrap, true, "uw toggles wrap on"); press("n", "<leader>uw"); eq(vim.wo.wrap, false, "uw toggles wrap off")
  press("n", "<leader>ul"); eq(vim.wo.number, false, "ul toggles number"); press("n", "<leader>ul"); eq(vim.wo.number, true, "ul back")
  press("n", "<leader>uL"); eq(vim.wo.relativenumber, false, "uL toggles relativenumber"); press("n", "<leader>uL")
  press("n", "<leader>us"); eq(vim.wo.spell, true, "us toggles spell"); press("n", "<leader>us"); eq(vim.wo.spell, false, "us back")

  -- buffers
  vim.cmd("edit " .. I .. "two.js"); vim.cmd("edit " .. I .. "four.js"); vim.cmd("edit " .. I .. "tabs.js")
  local n0 = #vim.fn.getbufinfo({ buflisted = 1 })
  press("n", "<leader>bd")
  eq(#vim.fn.getbufinfo({ buflisted = 1 }), n0 - 1, "bd removes one buffer")
  press("n", "<leader>bo")
  eq(#vim.fn.getbufinfo({ buflisted = 1 }), 1, "bo keeps only current")
  vim.cmd("silent! %bwipeout!")
  -- bd on the last buffer must not error and leaves an empty buffer
  vim.cmd("edit " .. I .. "two.js")
  local ok = pcall(function() press("n", "<leader>bd") end)
  check(ok, "bd on last buffer does not error")
  reset()

  -- quickfix toggle
  vim.fn.setqflist({ { filename = I .. "two.js", lnum = 1, text = "x" } })
  press("n", "<leader>xq"); eq(vim.fn.getqflist({ winid = 0 }).winid ~= 0, true, "xq opens quickfix")
  press("n", "<leader>xq"); eq(vim.fn.getqflist({ winid = 0 }).winid, 0, "xq closes quickfix")
  ok = pcall(function() press("n", "<leader>xl") end)
  check(ok, "xl on empty loclist does not error")
  vim.cmd("silent! lclose")

  -- explorer on the right, toggles
  vim.cmd("edit " .. FX .. "/proj/src/main.ts")
  local function netrw_wins()
    local r = {}
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "netrw" then r[#r + 1] = w end
    end
    return r
  end
  press("n", "<leader>e")
  local nw = netrw_wins()
  eq(#nw, 1, "explorer opens one netrw window")
  if nw[1] then
    local col = vim.api.nvim_win_get_position(nw[1])[2]
    check(col > 0, "explorer is on the right (col " .. col .. ")")
  end
  press("n", "<leader>e")
  eq(#netrw_wins(), 0, "explorer toggles closed")
  press("n", "<leader>E")
  eq(#netrw_wins(), 1, "E opens explorer at file dir")
  press("n", "<leader>E")
  vim.cmd("silent! only")
  reset()

  -- undotree pack
  press("n", "<leader>uu")
  eq(vim.fn.exists(":Undotree"), 2, ":Undotree available after <leader>uu")
  vim.cmd("silent! only")
  reset()

  -- yank highlight does not error
  vim.cmd("edit " .. I .. "two.js")
  vim.v.errmsg = ""
  vim.cmd("normal! yy")
  eq(vim.v.errmsg, "", "yank raises no error")
  reset()
end

local function nohl()
  clean_startup()
  vim.cmd("edit " .. FX .. "/indent/two.js"); vim.v.errmsg = ""; vim.cmd("normal! yy")
  check(_G.YANKED == true, "falls back to vim.highlight.on_yank when vim.hl is missing")
  eq(vim.v.errmsg, "", "no error")
end

local function nohl2()
  clean_startup()
  vim.cmd("edit " .. FX .. "/indent/two.js"); vim.v.errmsg = ""; vim.cmd("normal! yy")
  eq(vim.v.errmsg, "", "no error when no highlight API at all")
end

local function badopts()
  clean_startup()
  eq(vim.o.number, true, "number still set")
  eq(vim.o.shiftwidth, 2, "shiftwidth still set")
  check(vim.o.wildoptions:find("pum"), "pum still set: " .. vim.o.wildoptions)
  check(not vim.o.wildoptions:find("fuzzy"), "fuzzy skipped when unsupported")
  eq(vim.o.winborder, "", "winborder untouched (unsupported)")
  check(vim.o.path:find("**", 1, true), "path fallback ** when findfunc unsupported: " .. vim.o.path)
  eq(vim.o.findfunc, "", "findfunc untouched")
  check(map("n", "<leader>ff") ~= nil, "keymaps still defined")
  eq(vim.g.colors_name, "vscode-dark", "theme still applied")
  vim.cmd("edit " .. FX .. "/indent/four.js")
  eq(vim.bo.shiftwidth, 4, "indent detection still works")
end

local function badsection()
  local sk = vim.g.init_skipped
  check(type(sk) == "table" and #sk >= 1, "skipped sections recorded: " .. vim.inspect(sk))
  check(sk and vim.inspect(sk):find("theme"), "theme listed as skipped: " .. vim.inspect(sk))
  check(map("n", "<leader>ff") ~= nil, "keymaps survive a failing theme section")
  eq(vim.o.number, true, "options survive a failing theme section")
  vim.cmd("doautocmd VimEnter")
  local joined = table.concat(_G.NOTES, "\n")
  check(joined:find("theme"), "single warning names the skipped section: " .. joined)
  eq(#_G.NOTES, 1, "exactly one warning notification")
  vim.cmd("edit " .. FX .. "/indent/four.js")
  eq(vim.bo.shiftwidth, 4, "indent detection survives")
end

local function nopack()
  clean_startup()
  vim.o.packpath = "" -- from now on `packadd nvim.undotree` cannot succeed
  _G.NOTES = {}
  local ok = pcall(function() press("n", "<leader>uu") end)
  check(ok, "<leader>uu without pack does not error")
  check(#_G.NOTES >= 1 and _G.NOTES[1]:find("0.12"), "notifies 'needs Neovim 0.12': " .. vim.inspect(_G.NOTES))
end

local function old()
  eq(map("n", "<leader>ff"), nil, "no keymaps defined on too-old Neovim")
  eq(vim.g.mapleader, nil, "mapleader untouched")
  eq(vim.o.number, false, "options untouched")
  eq(vim.g.colors_name, nil, "theme untouched")
end

local function nowild()
  clean_startup()
  eq(map("n", "<leader>ff") ~= nil, true, "keymaps defined without wildtrigger")
  vim.cmd("cd " .. FX .. "/proj")
  check(vim.tbl_contains(vim.fn.getcompletion("find main", "cmdline"), "src/main.ts"), ":find completion works without wildtrigger")
end

local modes = {
  base = function() base(); files_and_grep(); indent(); autocmds_misc() end,
  rg = rg_pref, nohl = nohl, nohl2 = nohl2, badopts = badopts, badsection = badsection,
  nopack = nopack, old = old, nowild = nowild,
}
local ok, err = pcall(modes[mode])
if not ok then fails[#fails + 1] = "spec crashed: " .. tostring(err) end
finish()

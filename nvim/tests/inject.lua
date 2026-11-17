-- Loaded with `--cmd "luafile inject.lua"` BEFORE init.lua. Simulates older/limited Neovim builds.
local mode = vim.env.SPEC or "base"

-- capture notifications so the spec can inspect them
_G.NOTES = {}
local real_notify = vim.notify
vim.notify = function(msg, level, opts)
  _G.NOTES[#_G.NOTES + 1] = tostring(msg)
end

-- bad[name] = true  -> every assignment raises; bad[name] = "str" -> raises only if the value contains str
local function proxy_o(bad)
  local real = vim.o
  vim.o = setmetatable({}, {
    __index = function(_, k) return real[k] end,
    __newindex = function(_, k, v)
      local b = bad[k]
      if b == true or (type(b) == "string" and tostring(v):find(b, 1, true)) then
        error("E474: Invalid argument: " .. k)
      end
      real[k] = v
    end,
  })
end

if mode == "nohl" then
  vim.hl = false -- (nil would just lazy-reload the module)
  _G.YANKED = false
  vim.highlight = { on_yank = function() _G.YANKED = true end }
elseif mode == "nohl2" then
  vim.hl = false
  vim.highlight = false
elseif mode == "badopts" then
  proxy_o({ findfunc = true, winborder = true, smoothscroll = true, jumpoptions = true, wildoptions = "fuzzy" })
elseif mode == "badsection" then
  -- make the theme section blow up
  local real = vim.api.nvim_set_hl
  vim.api.nvim_set_hl = function(...) error("boom: nvim_set_hl unavailable") end
  _G.REAL_SET_HL = real
elseif mode == "old" then
  local real = vim.fn.has
  vim.fn.has = function(feat)
    if feat == "nvim-0.8" then return 0 end
    return real(feat)
  end
elseif mode == "nowild" then
  -- no wildtrigger / cmdcomplete_info / setcmdline (pre-0.11 style cmdline)
  local real = vim.fn.exists
  vim.fn.exists = function(what)
    if what == "*wildtrigger" or what == "*cmdcomplete_info" or what == "*setcmdline" then return 0 end
    return real(what)
  end
end

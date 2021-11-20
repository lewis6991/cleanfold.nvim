local api = vim.api
local fn = vim.fn

local M = {}

local ffi = require("ffi")
ffi.cdef'int curwin_col_off(void);'

local get_gutter_width = function()
  return ffi.C.curwin_col_off();
end

local function mangle_line(line)

  local commentstring = vim.split(vim.bo.commentstring, "%%s")[1]

  for _, marker in ipairs(vim.split(vim.wo.foldmarker, ",")) do
    -- Remove marker if it is apart of a comment
    line = fn.substitute(line, commentstring..'\\(.*\\)\\zs'..marker, '\1', 'g')
  end

  if commentstring ~= '' then
    -- Remove commentstring if there is only whitespace before it.
    line = fn.substitute(line, '^\\s*'..commentstring, '', 'g')
  end

  -- Remove leading whitespace
  line = line:gsub('^%s+', '')

  if vim.bo.filetype == 'scala' then
    -- Remove any text after the return type of a def
    line = fn.substitute(line, [[\({\|=\).\{-}$]] , '', 'g')
  end

  return line
end

local function getline(lno)
  return api.nvim_buf_get_lines(0, lno-1, lno, false)[1]
end

function M.foldtext()
  local fs = vim.v.foldstart
  local fe = vim.v.foldend

  local line = mangle_line(getline(fs))
  local fold_size = fe - fs + 1
  local indent = vim.bo.shiftwidth * (vim.v.foldlevel - 1)

  local padding =
    api.nvim_win_get_width(0) -
    get_gutter_width() -
    #line -
    #tostring(fold_size) -
    indent -
    1

  return
    string.rep(' ', indent)..
    line..
    string.rep(' ', padding)..
    fold_size..
    ' '
end

function M.setup()
  vim.cmd[[
    set foldtext=luaeval(\"require('cleanfold').foldtext()\")
  ]]
end

return M

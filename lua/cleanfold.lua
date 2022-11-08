local api = vim.api
local fn = vim.fn

local M = {}

local ft_handlers = {
  scala = function(line)
    -- Remove any text after the return type of a def
    return fn.substitute(line, [[\({\|=\).\{-}$]] , '', 'g')
  end
}

local function get_gutter_width(win)
  return vim.fn.getwininfo(win)[1].textoff
end

local function mangle_line(line)
  local commentstring = vim.split(vim.bo.commentstring, "%%s")[1]

  if vim.wo.foldmethod == 'marker' then
    for _, marker in ipairs(vim.split(vim.wo.foldmarker, ",")) do
      -- Remove marker if it is apart of a comment
      line = fn.substitute(line, commentstring..'\\(.*\\)\\zs'..marker, '\1', 'g')
    end
  end

  if commentstring ~= '' then
    -- Remove commentstring if there is only whitespace before it.
    line = fn.substitute(line, '^\\s*'..commentstring, '', 'g')
  end

  -- Remove leading whitespace
  line = line:gsub('^%s+', '')

  local ft = vim.bo.filetype

  if ft_handlers[ft] then
    -- Remove any text after the return type of a def
    line = ft_handlers[ft](line)
  end

  return line
end

local function getline(lno)
  return api.nvim_buf_get_lines(0, lno-1, lno, false)[1]
end

local RIGHT_PAD = 2

function M.foldtext()
  local fs = vim.v.foldstart
  local fe = vim.v.foldend

  local line = mangle_line(getline(fs))
  local fold_size = fe - fs + 1
  local indent = vim.bo.shiftwidth * (vim.v.foldlevel - 1)

  local win = api.nvim_get_current_win()

  local padding =
    api.nvim_win_get_width(win) -
    get_gutter_width(win) -
    #line -
    #tostring(fold_size) -
    indent -
    RIGHT_PAD

  return
    string.rep(' ', indent)..
    line..
    string.rep(' ', padding)..
    fold_size..
    string.rep(' ', RIGHT_PAD)
end

-- TODO(lewis6991): remove
function M.setup()
end

return M

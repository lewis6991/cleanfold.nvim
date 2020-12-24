local api = vim.api

local M = {}

local function mangle_line(line)

  local commentstring = vim.split(vim.bo.commentstring, "%%s")[1]

  for _, marker in ipairs(vim.split(vim.wo.foldmarker, ",")) do
    -- Remove marker if it is apart of a comment
    line = vim.fn.substitute(line, commentstring..'.*\\zs'..marker, '', 'g')
  end

  if commentstring ~= '' then
    -- Remove commentstring and comment if there is text before it.
    line = vim.fn.substitute(line, '\\w.*\\zs'..commentstring..'.*', '', 'g')

    -- Remove commentstring if there is only whitespace before it.
    line = vim.fn.substitute(line, '^\\s*'..commentstring, '', 'g')
  end

  -- Remove leading whitespace
  line = vim.fn.substitute(line, '^\\s*' , '', 'g')

  if vim.bo.filetype == 'scala' then
    -- Remove any text after the return type of a def
    line = vim.fn.substitute(line, [[\({\|=\).\{-}$]] , '', 'g')
  end

  return line
end

local function getline(lno)
  return api.nvim_buf_get_lines(0, lno-1, lno, false)[1]
end

local function get_number_width()
  local maxnumber
    if vim.wo.number then
        maxnumber = api.nvim_buf_line_count(0)
    elseif vim.wo.relativenumber then
        maxnumber = api.nvim_win_get_height(0)
    else
        return 0
    end

    -- +1 to account for padding
    local actual = #tostring(maxnumber) + 1
    return math.max(actual, vim.wo.numberwidth)
end

local function get_info_columns_width()
  local wid = get_number_width()
  -- local wid = 0

  wid = wid + tonumber(vim.wo.foldcolumn)

  -- The ':sign place' output contains two header lines.
  -- The sign column is fixed at two columns.
  local s = vim.fn.sign_getplaced()
  if #s > 0 then
    wid = wid + 2
  end

  return wid
end

function M.foldtext()
  local fs = vim.v.foldstart
  local fe = vim.v.foldend

  local line = mangle_line(getline(fs))
  local fold_size = fe - fs + 1
  local fold_level_padding = vim.bo.shiftwidth * (vim.v.foldlevel - 1)

  -- -- s:GetInfoColumnsWidth() -
  local winwidth = api.nvim_win_get_width(0)

  local padding =
    winwidth -
    get_info_columns_width() -
    #line -
    #tostring(fold_size) -
    fold_level_padding -
    1

  return
    string.rep(' ', fold_level_padding)..
    line..
    string.rep(' ', padding)..
    fold_size..
    ' '
end

function M.setup()
  vim.cmd([[set foldtext=luaeval(\"require('cleanfold').foldtext()\")]])
end

return M

local M = {}

local RESULTS_BUF_NAME = "[ducklens results]"
local ANALYSIS_BUF_NAME = "[ducklens types]"

--- Find or create a named scratch buffer in a bottom split.
---@param name string buffer name
---@param filetype string
---@param height? number
---@return number buf
---@return number win
local function get_output_buf(name, filetype, height)
  height = height or 15

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name:match(vim.pesc(name) .. "$") then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      return buf, win
    end
  end

  vim.cmd("botright " .. height .. "new")
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = filetype

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, desc = "Close results" })

  return buf, win
end

--- Format a table of rows as aligned columns with Unicode box-drawing.
---@param rows table[]
---@return string[] lines
---@return string[] headers
local function format_table(rows)
  if #rows == 0 then
    return { "(no rows)" }, {}
  end

  local headers = {}
  local header_set = {}
  for key, _ in pairs(rows[1]) do
    if not header_set[key] then
      headers[#headers + 1] = key
      header_set[key] = true
    end
  end
  table.sort(headers)

  local widths = {}
  for _, h in ipairs(headers) do
    widths[h] = #h
  end
  for _, row in ipairs(rows) do
    for _, h in ipairs(headers) do
      local val = tostring(row[h] or "")
      widths[h] = math.max(widths[h], #val)
    end
  end

  local lines = {}

  local hdr_parts = {}
  for _, h in ipairs(headers) do
    hdr_parts[#hdr_parts + 1] = string.format("%-" .. widths[h] .. "s", h)
  end
  lines[#lines + 1] = table.concat(hdr_parts, " │ ")

  local sep_parts = {}
  for _, h in ipairs(headers) do
    sep_parts[#sep_parts + 1] = string.rep("─", widths[h])
  end
  lines[#lines + 1] = table.concat(sep_parts, "─┼─")

  for _, row in ipairs(rows) do
    local parts = {}
    for _, h in ipairs(headers) do
      local val = tostring(row[h] or "")
      parts[#parts + 1] = string.format("%-" .. widths[h] .. "s", val)
    end
    lines[#lines + 1] = table.concat(parts, " │ ")
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = string.format("(%d row%s)", #rows, #rows == 1 and "" or "s")

  return lines, headers
end

--- Show type analysis results.
---@param rows table[]
---@param filepath string
---@param format_name string
function M.show_analysis(rows, filepath, format_name)
  local lines, _ = format_table(rows)

  local basename = vim.fn.fnamemodify(filepath, ":t")
  table.insert(lines, 1, "")
  table.insert(lines, 1, string.format("Column Types — %s [%s]", basename, format_name))

  local height = math.min(#lines + 1, 20)
  local buf, _ = get_output_buf(ANALYSIS_BUF_NAME, "text", height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("ducklens_display")
  vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)
  if #lines >= 3 then
    vim.api.nvim_buf_add_highlight(buf, ns, "Directory", 2, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 3, 0, -1)
  end
end

--- Show query results.
---@param rows table[]
---@param sql string
function M.show_results(rows, sql)
  local lines, _ = format_table(rows)

  local short_sql = sql:gsub("%s+", " ")
  if #short_sql > 80 then
    short_sql = short_sql:sub(1, 77) .. "..."
  end
  table.insert(lines, 1, "")
  table.insert(lines, 1, "Query: " .. short_sql)

  local height = math.min(#lines + 1, 25)
  local buf, _ = get_output_buf(RESULTS_BUF_NAME, "text", height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("ducklens_display")
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, -1)
  if #lines >= 3 then
    vim.api.nvim_buf_add_highlight(buf, ns, "Directory", 2, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 3, 0, -1)
  end
end

--- Show plain text in a scratch buffer.
---@param text string
---@param filetype string
---@param title string
function M.show_text(text, filetype, title)
  local lines = vim.split(text, "\n", { trimempty = true })
  table.insert(lines, 1, "")
  table.insert(lines, 1, title)

  local height = math.min(#lines + 1, 25)
  local buf, _ = get_output_buf("[ducklens " .. title .. "]", filetype, height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("ducklens_display")
  vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)
end

return M

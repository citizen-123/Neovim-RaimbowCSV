local M = {}

local RESULTS_BUF_NAME = "[csv-sql results]"
local ANALYSIS_BUF_NAME = "[csv-sql types]"

--- Find or create a named scratch buffer in a bottom split.
---@param name string buffer name
---@param filetype string
---@param height? number
---@return number buf
---@return number win
local function get_output_buf(name, filetype, height)
  height = height or 15

  -- Reuse existing buffer if open
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name:match(vim.pesc(name) .. "$") then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      return buf, win
    end
  end

  -- Create new split
  vim.cmd("botright " .. height .. "new")
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = filetype

  -- Close with q
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, desc = "Close results" })

  return buf, win
end

--- Format a table of rows as aligned columns.
---@param rows table[]  array of {key = value} objects
---@return string[] lines
---@return string[] headers
local function format_table(rows)
  if #rows == 0 then
    return { "(no rows)" }, {}
  end

  -- Collect headers preserving order from first row
  local headers = {}
  local header_set = {}
  for key, _ in pairs(rows[1]) do
    if not header_set[key] then
      headers[#headers + 1] = key
      header_set[key] = true
    end
  end
  table.sort(headers)

  -- Compute column widths
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

  -- Build lines
  local lines = {}

  -- Header line
  local hdr_parts = {}
  for _, h in ipairs(headers) do
    hdr_parts[#hdr_parts + 1] = string.format("%-" .. widths[h] .. "s", h)
  end
  lines[#lines + 1] = table.concat(hdr_parts, " │ ")

  -- Separator
  local sep_parts = {}
  for _, h in ipairs(headers) do
    sep_parts[#sep_parts + 1] = string.rep("─", widths[h])
  end
  lines[#lines + 1] = table.concat(sep_parts, "─┼─")

  -- Data rows
  for _, row in ipairs(rows) do
    local parts = {}
    for _, h in ipairs(headers) do
      local val = tostring(row[h] or "")
      parts[#parts + 1] = string.format("%-" .. widths[h] .. "s", val)
    end
    lines[#lines + 1] = table.concat(parts, " │ ")
  end

  -- Row count footer
  lines[#lines + 1] = ""
  lines[#lines + 1] = string.format("(%d row%s)", #rows, #rows == 1 and "" or "s")

  return lines, headers
end

--- Show type analysis results in a scratch buffer.
---@param rows table[]  DuckDB DESCRIBE output
---@param filepath string
function M.show_analysis(rows, filepath)
  local lines, _ = format_table(rows)

  -- Prepend title
  local basename = vim.fn.fnamemodify(filepath, ":t")
  table.insert(lines, 1, "")
  table.insert(lines, 1, "Column Types — " .. basename)

  local height = math.min(#lines + 1, 20)
  local buf, _ = get_output_buf(ANALYSIS_BUF_NAME, "text", height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Highlight the title and header
  local ns = vim.api.nvim_create_namespace("csv_sql_display")
  vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)
  if #lines >= 3 then
    vim.api.nvim_buf_add_highlight(buf, ns, "Directory", 2, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 3, 0, -1)
  end
end

--- Show query results in a scratch buffer.
---@param rows table[]
---@param sql string  the query that produced these results
function M.show_results(rows, sql)
  local lines, _ = format_table(rows)

  -- Prepend query as a comment
  local short_sql = sql:gsub("%s+", " ")
  if #short_sql > 80 then
    short_sql = short_sql:sub(1, 77) .. "..."
  end
  table.insert(lines, 1, "")
  table.insert(lines, 1, "Query: " .. short_sql)

  local height = math.min(#lines + 1, 25)
  local buf, _ = get_output_buf(RESULTS_BUF_NAME, "text", height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("csv_sql_display")
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
  local buf, _ = get_output_buf("[csv-sql " .. title .. "]", filetype, height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("csv_sql_display")
  vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)
end

return M

local M = {}

local NS = vim.api.nvim_create_namespace("rainbow_csv_hl")

local PALETTE = {
  { fg = "#E06C75", name = "RainbowCsvCol1" },  -- red
  { fg = "#98C379", name = "RainbowCsvCol2" },  -- green
  { fg = "#E5C07B", name = "RainbowCsvCol3" },  -- yellow
  { fg = "#61AFEF", name = "RainbowCsvCol4" },  -- blue
  { fg = "#C678DD", name = "RainbowCsvCol5" },  -- magenta
  { fg = "#56B6C2", name = "RainbowCsvCol6" },  -- cyan
  { fg = "#D19A66", name = "RainbowCsvCol7" },  -- orange
  { fg = "#BE5046", name = "RainbowCsvCol8" },  -- dark red
  { fg = "#7EC8E3", name = "RainbowCsvCol9" },  -- light blue
  { fg = "#C3E88D", name = "RainbowCsvCol10" }, -- lime
}

local hl_defined = false

local function ensure_highlights()
  if hl_defined then
    return
  end
  for _, entry in ipairs(PALETTE) do
    vim.api.nvim_set_hl(0, entry.name, { fg = entry.fg, bold = true })
  end
  -- Dimmed delimiter highlight
  vim.api.nvim_set_hl(0, "RainbowCsvDelim", { fg = "#5C6370" })
  hl_defined = true
end

--- Split a line by delimiter, returning byte-offset spans.
---@param line string
---@param delim string
---@return table[] list of {col_start, col_end, col_index}
local function split_spans(line, delim)
  local spans = {}
  local col_idx = 0
  local pos = 1
  local delim_len = #delim
  local in_quotes = false

  local field_start = 1

  local i = 1
  while i <= #line do
    local ch = line:sub(i, i)
    if ch == '"' then
      in_quotes = not in_quotes
      i = i + 1
    elseif not in_quotes and line:sub(i, i + delim_len - 1) == delim then
      -- End of field
      spans[#spans + 1] = {
        start = field_start - 1, -- 0-indexed byte offset
        finish = i - 2,          -- inclusive end of field content
        delim_start = i - 1,     -- delimiter position
        delim_end = i - 1 + delim_len - 1,
        col = col_idx,
      }
      col_idx = col_idx + 1
      i = i + delim_len
      field_start = i
    else
      i = i + 1
    end
  end

  -- Last field (no trailing delimiter)
  spans[#spans + 1] = {
    start = field_start - 1,
    finish = #line - 1,
    delim_start = nil,
    delim_end = nil,
    col = col_idx,
  }

  return spans
end

--- Apply rainbow column highlights to a buffer.
---@param buf number
---@param delim string
function M.apply(buf, delim)
  ensure_highlights()
  M.clear(buf)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local spans = split_spans(line, delim)
    for _, span in ipairs(spans) do
      local hl = PALETTE[(span.col % #PALETTE) + 1].name

      -- Highlight field content
      if span.finish >= span.start then
        vim.api.nvim_buf_set_extmark(buf, NS, lnum - 1, span.start, {
          end_col = span.finish + 1,
          hl_group = hl,
          priority = 100,
        })
      end

      -- Dim the delimiter
      if span.delim_start then
        vim.api.nvim_buf_set_extmark(buf, NS, lnum - 1, span.delim_start, {
          end_col = span.delim_end + 1,
          hl_group = "RainbowCsvDelim",
          priority = 101,
        })
      end
    end
  end
end

--- Clear rainbow highlights.
---@param buf number
function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
end

M.NS = NS
M.PALETTE = PALETTE
M.split_spans = split_spans

return M

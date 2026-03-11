local M = {}

local NS = vim.api.nvim_create_namespace("rainbow_csv_align")

--- Parse all rows into fields, respecting quoted values.
---@param lines string[]
---@param delim string
---@return string[][] fields per row
local function parse_fields(lines, delim)
  local rows = {}
  for _, line in ipairs(lines) do
    local fields = {}
    local field = {}
    local in_quotes = false
    local i = 1
    local delim_len = #delim

    while i <= #line do
      local ch = line:sub(i, i)
      if ch == '"' then
        in_quotes = not in_quotes
        field[#field + 1] = ch
        i = i + 1
      elseif not in_quotes and line:sub(i, i + delim_len - 1) == delim then
        fields[#fields + 1] = table.concat(field)
        field = {}
        i = i + delim_len
      else
        field[#field + 1] = ch
        i = i + 1
      end
    end
    fields[#fields + 1] = table.concat(field)
    rows[#rows + 1] = fields
  end
  return rows
end

--- Compute max display width per column.
---@param rows string[][]
---@return number[]
local function column_widths(rows)
  local widths = {}
  for _, fields in ipairs(rows) do
    for col, val in ipairs(fields) do
      local w = vim.fn.strdisplaywidth(val)
      widths[col] = math.max(widths[col] or 0, w)
    end
  end
  return widths
end

--- Apply virtual-text alignment (non-destructive).
--- Inserts inline virtual text (padding spaces) after each field.
---@param buf number
---@param delim string
function M.virtual_align(buf, delim)
  M.clear(buf)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local rows = parse_fields(lines, delim)
  local widths = column_widths(rows)

  for lnum, line in ipairs(lines) do
    local fields = rows[lnum]
    -- Walk through the line and find each delimiter position, inserting
    -- virtual padding before each delimiter.
    local byte_pos = 0
    local in_quotes = false
    local col_idx = 1
    local field_start = 0
    local delim_len = #delim
    local i = 1

    while i <= #line do
      local ch = line:sub(i, i)
      if ch == '"' then
        in_quotes = not in_quotes
        i = i + 1
      elseif not in_quotes and line:sub(i, i + delim_len - 1) == delim then
        -- End of field col_idx; delimiter at byte i-1 (0-indexed)
        local field_val = fields[col_idx] or ""
        local display_w = vim.fn.strdisplaywidth(field_val)
        local target_w = widths[col_idx] or display_w
        local pad = target_w - display_w

        if pad > 0 then
          vim.api.nvim_buf_set_extmark(buf, NS, lnum - 1, i - 1, {
            virt_text = { { string.rep(" ", pad), "Normal" } },
            virt_text_pos = "inline",
            priority = 50,
          })
        end

        col_idx = col_idx + 1
        i = i + delim_len
      else
        i = i + 1
      end
    end
  end
end

--- Align columns in-place by padding fields with spaces.
---@param buf number
---@param delim string
function M.inplace_align(buf, delim)
  M.clear(buf)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local rows = parse_fields(lines, delim)
  local widths = column_widths(rows)

  local new_lines = {}
  for _, fields in ipairs(rows) do
    local padded = {}
    for col, val in ipairs(fields) do
      local target = widths[col] or 0
      local pad = target - vim.fn.strdisplaywidth(val)
      padded[#padded + 1] = val .. string.rep(" ", math.max(0, pad))
    end
    new_lines[#new_lines + 1] = table.concat(padded, delim .. " ")
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
end

--- Remove in-place alignment (strip trailing spaces from fields).
---@param buf number
---@param delim string
function M.inplace_unalign(buf, delim)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local rows = parse_fields(lines, delim)

  local new_lines = {}
  for _, fields in ipairs(rows) do
    local trimmed = {}
    for _, val in ipairs(fields) do
      trimmed[#trimmed + 1] = val:match("^(.-)%s*$")
    end
    new_lines[#new_lines + 1] = table.concat(trimmed, delim)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
end

--- Clear virtual alignment extmarks.
---@param buf number
function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
end

M.NS = NS

return M

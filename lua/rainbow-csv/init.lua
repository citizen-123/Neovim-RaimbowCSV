local detect = require("rainbow-csv.detect")
local highlight = require("rainbow-csv.highlight")
local align = require("rainbow-csv.align")

local M = {}

---@class RainbowCsvBufState
---@field enabled boolean
---@field delim string
---@field delim_name string
---@field align_mode "none"|"virtual"|"inplace"
---@field header_row number|nil  -- 1-indexed row used as header, nil = no header

---@type table<number, RainbowCsvBufState>
local buf_state = {}

--- Get or initialize state for a buffer.
---@param buf number
---@return RainbowCsvBufState
local function get_state(buf)
  if not buf_state[buf] then
    local delim, name = detect.detect(buf)
    buf_state[buf] = {
      enabled = false,
      delim = delim,
      delim_name = name,
      align_mode = "none",
      header_row = 1,
    }
  end
  return buf_state[buf]
end

--- Enable rainbow highlighting for the current buffer.
---@param buf? number
function M.enable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)
  state.enabled = true
  highlight.apply(buf, state.delim)
  vim.notify(("RainbowCSV enabled (%s-delimited)"):format(state.delim_name), vim.log.levels.INFO)
end

--- Disable rainbow highlighting.
---@param buf? number
function M.disable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)
  state.enabled = false
  highlight.clear(buf)
  vim.notify("RainbowCSV disabled", vim.log.levels.INFO)
end

--- Toggle rainbow highlighting.
---@param buf? number
function M.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)
  if state.enabled then
    M.disable(buf)
  else
    M.enable(buf)
  end
end

--- Cycle alignment mode: none → virtual → inplace → none
---@param buf? number
function M.cycle_align(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)

  if state.align_mode == "none" then
    state.align_mode = "virtual"
    align.virtual_align(buf, state.delim)
    vim.notify("Alignment: virtual (buffer unchanged)", vim.log.levels.INFO)
  elseif state.align_mode == "virtual" then
    align.clear(buf)
    state.align_mode = "inplace"
    align.inplace_align(buf, state.delim)
    vim.notify("Alignment: in-place (buffer modified)", vim.log.levels.WARN)
  else
    state.align_mode = "none"
    align.inplace_unalign(buf, state.delim)
    align.clear(buf)
    vim.notify("Alignment: off", vim.log.levels.INFO)
  end

  -- Re-apply highlights if enabled (alignment may shift byte offsets)
  if state.enabled then
    highlight.apply(buf, state.delim)
  end
end

--- Set alignment to a specific mode.
---@param mode "none"|"virtual"|"inplace"
---@param buf? number
function M.set_align(mode, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)

  -- Clean up current mode
  if state.align_mode == "virtual" then
    align.clear(buf)
  elseif state.align_mode == "inplace" then
    align.inplace_unalign(buf, state.delim)
  end

  state.align_mode = mode

  if mode == "virtual" then
    align.virtual_align(buf, state.delim)
  elseif mode == "inplace" then
    align.inplace_align(buf, state.delim)
  end

  if state.enabled then
    highlight.apply(buf, state.delim)
  end
end

--- Override the detected delimiter.
---@param delim string
---@param buf? number
function M.set_delimiter(delim, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)

  local names = { [","] = "comma", ["\t"] = "tab", ["|"] = "pipe" }
  state.delim = delim
  state.delim_name = names[delim] or "custom"

  -- Reapply everything with the new delimiter
  if state.align_mode == "virtual" then
    align.clear(buf)
    align.virtual_align(buf, delim)
  end

  if state.enabled then
    highlight.apply(buf, delim)
  end

  vim.notify(("Delimiter set to: %s"):format(state.delim_name), vim.log.levels.INFO)
end

--- Parse a single line into fields respecting quotes.
---@param line string
---@param delim string
---@return string[]
local function parse_line_fields(line, delim)
  local fields = {}
  local field = {}
  local in_quotes = false
  local delim_len = #delim
  local i = 1

  while i <= #line do
    local ch = line:sub(i, i)
    if ch == '"' then
      in_quotes = not in_quotes
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
  return fields
end

--- Show which column the cursor is in.
--- If header_row is set, displays the header name from that row.
--- If header_row is nil (no-header mode), displays only the column index.
---@param buf? number
function M.column_info(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col_byte = cursor[2]

  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""

  -- Walk the line to find which column the cursor is in
  local delim = state.delim
  local delim_len = #delim
  local col_idx = 0
  local in_quotes = false

  for i = 1, #line do
    if i - 1 > col_byte then
      break
    end
    local ch = line:sub(i, i)
    if ch == '"' then
      in_quotes = not in_quotes
    elseif not in_quotes and line:sub(i, i + delim_len - 1) == delim then
      if i - 1 <= col_byte then
        col_idx = col_idx + 1
      end
    end
  end

  if state.header_row then
    local header_line = vim.api.nvim_buf_get_lines(buf, state.header_row - 1, state.header_row, false)[1] or ""
    local headers = parse_line_fields(header_line, delim)
    local header_name = headers[col_idx + 1] or "?"
    vim.notify(("Column %d: %s"):format(col_idx + 1, header_name), vim.log.levels.INFO)
  else
    vim.notify(("Column %d"):format(col_idx + 1), vim.log.levels.INFO)
  end
end

--- Set which row contains headers (1-indexed).
---@param row number
---@param buf? number
function M.set_header_row(row, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)
  local line_count = vim.api.nvim_buf_line_count(buf)

  if row < 1 or row > line_count then
    vim.notify(("Invalid header row: %d (buffer has %d lines)"):format(row, line_count), vim.log.levels.ERROR)
    return
  end

  state.header_row = row
  vim.notify(("Header row set to line %d"):format(row), vim.log.levels.INFO)
end

--- Disable header row (headerless mode).
---@param buf? number
function M.no_header(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = get_state(buf)
  state.header_row = nil
  vim.notify("Header row disabled — column_info will show index only", vim.log.levels.INFO)
end

--- Refresh highlights after buffer edits.
---@param buf? number
function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local state = buf_state[buf]
  if not state or not state.enabled then
    return
  end
  highlight.apply(buf, state.delim)
end

--- Optional setup call for user config (currently a no-op placeholder).
---@param opts? table
function M.setup(opts)
  -- Reserved for future config (custom colors, auto-enable patterns, etc.)
end

return M

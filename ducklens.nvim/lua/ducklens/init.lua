local M = {}

local analyze = require("ducklens.analyze")
local query = require("ducklens.query")
local duckdb = require("ducklens.duckdb")
local formats = require("ducklens.formats")

--- Check DuckDB availability.
---@return boolean available
function M.check_health()
  local bin = duckdb.find_binary()
  if bin then
    vim.notify("ducklens: DuckDB found at: " .. bin, vim.log.levels.INFO)
    return true
  else
    vim.notify(
      "ducklens: DuckDB not found.\n"
        .. "  Install: https://duckdb.org/docs/installation\n"
        .. "  Or set g:ducklens_duckdb_path to the binary location.",
      vim.log.levels.ERROR
    )
    return false
  end
end

--- List supported file formats.
function M.supported()
  local lines = { "Supported formats:" }
  for _, fmt in ipairs(formats.formats) do
    lines[#lines + 1] = string.format(
      "  %-10s  extensions: %s  (reader: %s)",
      fmt.name,
      table.concat(fmt.extensions, ", "),
      fmt.reader
    )
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Expose submodule functions

M.analyze = analyze.analyze
M.generate_ddl = analyze.generate_ddl
M.get_types = analyze.get_types
M.duckdb_to_sql = analyze.duckdb_to_sql
M.query = query.query
M.prompt = query.prompt
M.editor = query.editor
M.detect_format = formats.detect
M.formats = formats

--- Setup (reserved for future config).
---@param opts? table
function M.setup(opts)
  -- Future: custom type mappings, additional formats, etc.
end

return M

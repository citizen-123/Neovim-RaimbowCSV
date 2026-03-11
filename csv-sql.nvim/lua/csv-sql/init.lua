local M = {}

local analyze = require("csv-sql.analyze")
local query = require("csv-sql.query")
local duckdb = require("csv-sql.duckdb")

--- Check DuckDB availability and report.
---@return boolean available
function M.check_health()
  local bin = duckdb.find_binary()
  if bin then
    vim.notify("csv-sql: DuckDB found at: " .. bin, vim.log.levels.INFO)
    return true
  else
    vim.notify(
      "csv-sql: DuckDB not found.\n"
        .. "  Install: https://duckdb.org/docs/installation\n"
        .. "  Or set g:csvsql_duckdb_path to the binary location.",
      vim.log.levels.ERROR
    )
    return false
  end
end

-- Expose submodule functions directly

--- Analyze column types of the current CSV buffer.
---@param buf? number
M.analyze = analyze.analyze

--- Generate a CREATE TABLE DDL statement from inferred types.
---@param buf? number
M.generate_ddl = analyze.generate_ddl

--- Get column types as a Lua table (synchronous).
---@param filepath string
---@return table[]|nil rows
---@return string|nil error
M.get_types = analyze.get_types

--- Run a SQL query against the current CSV buffer.
---@param sql string
---@param buf? number
M.query = query.query

--- Open a SQL input prompt.
---@param buf? number
M.prompt = query.prompt

--- Open the multi-line SQL editor scratch buffer.
---@param buf? number
M.editor = query.editor

--- Map DuckDB types to standard SQL types.
---@param duck_type string
---@return string
M.duckdb_to_sql = analyze.duckdb_to_sql

--- Setup (reserved for future config).
---@param opts? table
function M.setup(opts)
  -- Future: custom type mappings, default query templates, etc.
end

return M

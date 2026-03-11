local duckdb = require("csv-sql.duckdb")
local display = require("csv-sql.display")

local M = {}

--- Build the DESCRIBE query for a CSV file.
---@param filepath string
---@return string sql
local function describe_sql(filepath)
  -- Use read_csv with auto-detection for robust parsing
  return string.format(
    "DESCRIBE SELECT * FROM read_csv('%s', auto_detect=true, header=true);",
    filepath:gsub("'", "''")
  )
end

--- Build a sampling query that shows value stats per column.
---@param filepath string
---@return string sql
local function stats_sql(filepath)
  local escaped = filepath:gsub("'", "''")
  return string.format([[
WITH src AS (
  SELECT * FROM read_csv('%s', auto_detect=true, header=true)
),
col_info AS (
  DESCRIBE SELECT * FROM read_csv('%s', auto_detect=true, header=true)
)
SELECT
  ci.column_name,
  ci.column_type,
  ci.null AS nullable,
  (SELECT count(*) FROM src) AS total_rows,
  (SELECT count(*) FROM src WHERE src."' || ci.column_name || '" IS NULL) AS null_count
FROM col_info ci;
]], escaped, escaped)
end

--- Analyze the current buffer's file and display inferred types.
---@param buf? number
function M.analyze(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    vim.notify("csv-sql: Buffer has no file path. Save the file first.", vim.log.levels.ERROR)
    return
  end

  vim.notify("csv-sql: Analyzing types...", vim.log.levels.INFO)

  local sql = describe_sql(filepath)

  duckdb.run_async(sql, {}, function(stdout, stderr, code)
    if code ~= 0 then
      vim.notify("csv-sql: DuckDB error:\n" .. stderr, vim.log.levels.ERROR)
      return
    end

    local ok, rows = pcall(vim.json.decode, stdout)
    if not ok or not rows then
      vim.notify("csv-sql: Failed to parse DuckDB output", vim.log.levels.ERROR)
      return
    end

    display.show_analysis(rows, filepath)
  end)
end

--- Return type info as a Lua table (synchronous, for programmatic use).
---@param filepath string
---@return table[]|nil rows
---@return string|nil error
function M.get_types(filepath)
  local sql = describe_sql(filepath)
  local stdout, stderr, code = duckdb.run(sql)

  if code ~= 0 then
    return nil, stderr
  end

  local ok, rows = pcall(vim.json.decode, stdout)
  if not ok or not rows then
    return nil, "Failed to parse DuckDB JSON output"
  end

  return rows, nil
end

--- Generate a CREATE TABLE statement from inferred types.
---@param buf? number
function M.generate_ddl(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    vim.notify("csv-sql: Buffer has no file path.", vim.log.levels.ERROR)
    return
  end

  local rows, err = M.get_types(filepath)
  if not rows then
    vim.notify("csv-sql: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Derive a table name from the filename
  local basename = vim.fn.fnamemodify(filepath, ":t:r")
  local table_name = basename:gsub("[^%w_]", "_"):lower()

  local columns = {}
  for _, row in ipairs(rows) do
    local col_name = row.column_name
    local col_type = M.duckdb_to_sql(row.column_type)
    local nullable = row["null"] ~= "NO" and "" or " NOT NULL"
    columns[#columns + 1] = string.format("  %-30s %s%s", '"' .. col_name .. '"', col_type, nullable)
  end

  local ddl = string.format(
    "CREATE TABLE %s (\n%s\n);",
    table_name,
    table.concat(columns, ",\n")
  )

  display.show_text(ddl, "sql", "CREATE TABLE — " .. table_name)
end

--- Map DuckDB types to standard SQL types.
---@param duck_type string
---@return string
function M.duckdb_to_sql(duck_type)
  local upper = duck_type:upper()
  local map = {
    ["BIGINT"]    = "BIGINT",
    ["INTEGER"]   = "INTEGER",
    ["SMALLINT"]  = "SMALLINT",
    ["TINYINT"]   = "SMALLINT",
    ["HUGEINT"]   = "NUMERIC(38,0)",
    ["DOUBLE"]    = "DOUBLE PRECISION",
    ["FLOAT"]     = "REAL",
    ["DECIMAL"]   = "DECIMAL",
    ["BOOLEAN"]   = "BOOLEAN",
    ["DATE"]      = "DATE",
    ["TIME"]      = "TIME",
    ["TIMESTAMP"] = "TIMESTAMP",
    ["TIMESTAMP WITH TIME ZONE"] = "TIMESTAMP WITH TIME ZONE",
    ["VARCHAR"]   = "TEXT",
    ["BLOB"]      = "BYTEA",
    ["UUID"]      = "UUID",
    ["INTERVAL"]  = "INTERVAL",
  }

  -- Handle parameterized types like DECIMAL(10,2)
  local base = upper:match("^(%w+)")
  return map[upper] or map[base] or duck_type
end

return M

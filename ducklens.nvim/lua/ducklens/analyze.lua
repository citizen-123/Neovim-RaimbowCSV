local duckdb = require("ducklens.duckdb")
local display = require("ducklens.display")
local formats = require("ducklens.formats")

local M = {}

--- Analyze column types for the current buffer's file.
---@param buf? number
function M.analyze(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    vim.notify("ducklens: Buffer has no file path. Save the file first.", vim.log.levels.ERROR)
    return
  end

  local reader, fmt, err = formats.reader_expr(filepath)
  if err then
    vim.notify("ducklens: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("ducklens: Analyzing types (" .. fmt.name .. ")...", vim.log.levels.INFO)

  local sql = string.format("DESCRIBE SELECT * FROM %s;", reader)

  duckdb.run_async(sql, {}, function(stdout, stderr, code)
    if code ~= 0 then
      vim.notify("ducklens: DuckDB error:\n" .. stderr, vim.log.levels.ERROR)
      return
    end

    local ok, rows = pcall(vim.json.decode, stdout)
    if not ok or not rows then
      vim.notify("ducklens: Failed to parse DuckDB output", vim.log.levels.ERROR)
      return
    end

    display.show_analysis(rows, filepath, fmt.name)
  end)
end

--- Return type info as a Lua table (synchronous).
---@param filepath string
---@return table[]|nil rows
---@return string|nil error
function M.get_types(filepath)
  local reader, _, err = formats.reader_expr(filepath)
  if err then
    return nil, err
  end

  local sql = string.format("DESCRIBE SELECT * FROM %s;", reader)
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
    vim.notify("ducklens: Buffer has no file path.", vim.log.levels.ERROR)
    return
  end

  local rows, err = M.get_types(filepath)
  if not rows then
    vim.notify("ducklens: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

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
    ["UBIGINT"]   = "NUMERIC(20,0)",
    ["UINTEGER"]  = "BIGINT",
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
    ["JSON"]      = "JSONB",
  }

  -- Handle parameterized types like DECIMAL(10,2)
  local base = upper:match("^(%w+)")

  -- Handle STRUCT/MAP/LIST — DuckDB nested types from JSON
  if base == "STRUCT" or base == "MAP" then
    return "JSONB"
  end
  if upper:match("^%w+%[%]$") or base == "LIST" then
    return "JSONB"
  end

  return map[upper] or map[base] or duck_type
end

return M

local M = {}

---@type string|nil
local duckdb_path = nil

--- Locate the DuckDB CLI binary.
---@return string|nil path
function M.find_binary()
  if duckdb_path then
    return duckdb_path
  end

  -- Check explicit user override first
  if vim.g.csvsql_duckdb_path then
    if vim.fn.executable(vim.g.csvsql_duckdb_path) == 1 then
      duckdb_path = vim.g.csvsql_duckdb_path
      return duckdb_path
    end
    vim.notify("csv-sql: g:csvsql_duckdb_path is set but not executable: " .. vim.g.csvsql_duckdb_path, vim.log.levels.ERROR)
    return nil
  end

  -- Search PATH
  if vim.fn.executable("duckdb") == 1 then
    duckdb_path = "duckdb"
    return duckdb_path
  end

  return nil
end

--- Run a DuckDB SQL query and return stdout, stderr, exit code.
--- Runs synchronously (blocking). For async, see run_async.
---@param sql string
---@param opts? { csv_mode?: boolean }
---@return string stdout
---@return string stderr
---@return number exit_code
function M.run(sql, opts)
  opts = opts or {}
  local bin = M.find_binary()
  if not bin then
    return "", "DuckDB not found. Install it or set g:csvsql_duckdb_path", 1
  end

  local args = { bin, "-json" }
  if opts.csv_mode then
    args = { bin, "-csv" }
  end

  -- Write SQL to a temp file to avoid shell escaping issues
  local tmpfile = vim.fn.tempname() .. ".sql"
  local f = io.open(tmpfile, "w")
  if not f then
    return "", "Failed to create temp SQL file", 1
  end
  f:write(sql)
  f:close()

  table.insert(args, "-c")
  table.insert(args, ".read " .. tmpfile)

  local result = vim.system(args, { text = true }):wait()

  os.remove(tmpfile)

  return result.stdout or "", result.stderr or "", result.code
end

--- Run a DuckDB query asynchronously.
---@param sql string
---@param opts? { csv_mode?: boolean }
---@param callback fun(stdout: string, stderr: string, exit_code: number)
function M.run_async(sql, opts, callback)
  opts = opts or {}
  local bin = M.find_binary()
  if not bin then
    vim.schedule(function()
      callback("", "DuckDB not found. Install it or set g:csvsql_duckdb_path", 1)
    end)
    return
  end

  local args = { bin, "-json" }
  if opts.csv_mode then
    args = { bin, "-csv" }
  end

  local tmpfile = vim.fn.tempname() .. ".sql"
  local f = io.open(tmpfile, "w")
  if not f then
    vim.schedule(function()
      callback("", "Failed to create temp SQL file", 1)
    end)
    return
  end
  f:write(sql)
  f:close()

  table.insert(args, "-c")
  table.insert(args, ".read " .. tmpfile)

  vim.system(args, { text = true }, function(result)
    os.remove(tmpfile)
    vim.schedule(function()
      callback(result.stdout or "", result.stderr or "", result.code)
    end)
  end)
end

return M

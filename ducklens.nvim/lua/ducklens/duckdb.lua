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
  if vim.g.ducklens_duckdb_path then
    if vim.fn.executable(vim.g.ducklens_duckdb_path) == 1 then
      duckdb_path = vim.g.ducklens_duckdb_path
      return duckdb_path
    end
    vim.notify(
      "ducklens: g:ducklens_duckdb_path is set but not executable: " .. vim.g.ducklens_duckdb_path,
      vim.log.levels.ERROR
    )
    return nil
  end

  if vim.fn.executable("duckdb") == 1 then
    duckdb_path = "duckdb"
    return duckdb_path
  end

  return nil
end

--- Run a DuckDB SQL query synchronously.
---@param sql string
---@param opts? { csv_mode?: boolean }
---@return string stdout
---@return string stderr
---@return number exit_code
function M.run(sql, opts)
  opts = opts or {}
  local bin = M.find_binary()
  if not bin then
    return "", "DuckDB not found. Install it or set g:ducklens_duckdb_path", 1
  end

  local output_flag = opts.csv_mode and "-csv" or "-json"

  local tmpfile = vim.fn.tempname() .. ".sql"
  local f = io.open(tmpfile, "w")
  if not f then
    return "", "Failed to create temp SQL file", 1
  end
  f:write(sql)
  f:close()

  local result = vim.system({ bin, output_flag, "-c", ".read " .. tmpfile }, { text = true }):wait()
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
      callback("", "DuckDB not found. Install it or set g:ducklens_duckdb_path", 1)
    end)
    return
  end

  local output_flag = opts.csv_mode and "-csv" or "-json"

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

  vim.system({ bin, output_flag, "-c", ".read " .. tmpfile }, { text = true }, function(result)
    os.remove(tmpfile)
    vim.schedule(function()
      callback(result.stdout or "", result.stderr or "", result.code)
    end)
  end)
end

return M

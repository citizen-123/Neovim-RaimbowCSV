local duckdb = require("csv-sql.duckdb")
local display = require("csv-sql.display")

local M = {}

---@type string[] command history
local history = {}

--- Build SQL that creates a view alias for the current file, then runs the user query.
---@param filepath string
---@param user_sql string
---@return string
local function wrap_query(filepath, user_sql)
  local escaped = filepath:gsub("'", "''")
  local basename = vim.fn.fnamemodify(filepath, ":t:r")
  local alias = basename:gsub("[^%w_]", "_"):lower()

  -- Create a view so the user can reference the table by a clean name
  -- Also expose it as 'csv' for convenience
  return string.format([[
CREATE OR REPLACE VIEW "%s" AS SELECT * FROM read_csv('%s', auto_detect=true, header=true);
CREATE OR REPLACE VIEW csv AS SELECT * FROM "%s";
%s
]], alias, escaped, alias, user_sql)
end

--- Execute a SQL query against the current buffer's CSV.
---@param sql string  user-provided SQL
---@param buf? number
function M.query(sql, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    vim.notify("csv-sql: Buffer has no file path. Save the file first.", vim.log.levels.ERROR)
    return
  end

  if sql == "" then
    vim.notify("csv-sql: No SQL provided.", vim.log.levels.WARN)
    return
  end

  -- Store in history
  history[#history + 1] = sql

  vim.notify("csv-sql: Running query...", vim.log.levels.INFO)

  local full_sql = wrap_query(filepath, sql)

  duckdb.run_async(full_sql, {}, function(stdout, stderr, code)
    if code ~= 0 then
      vim.notify("csv-sql: Query error:\n" .. stderr, vim.log.levels.ERROR)
      return
    end

    if stdout == "" or stdout:match("^%s*$") then
      vim.notify("csv-sql: Query returned no output.", vim.log.levels.INFO)
      return
    end

    -- Try JSON parse for tabular display
    local ok, rows = pcall(vim.json.decode, stdout)
    if ok and type(rows) == "table" and #rows > 0 then
      display.show_results(rows, sql)
    else
      -- Fallback: show raw output
      display.show_text(stdout, "text", "Query Result")
    end
  end)
end

--- Open an input prompt for a SQL query.
---@param buf? number
function M.prompt(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local basename = vim.fn.fnamemodify(filepath, ":t:r")
  local alias = basename:gsub("[^%w_]", "_"):lower()

  vim.ui.input({
    prompt = string.format("SQL (tables: %s, csv)> ", alias),
    completion = "file",
  }, function(input)
    if input and input ~= "" then
      M.query(input, buf)
    end
  end)
end

--- Open a scratch buffer for multi-line SQL editing.
--- Execute with a keybinding from within the scratch buffer.
---@param buf? number
function M.editor(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local basename = vim.fn.fnamemodify(filepath, ":t:r")
  local alias = basename:gsub("[^%w_]", "_"):lower()

  -- Create scratch split
  vim.cmd("botright 12new")
  local edit_buf = vim.api.nvim_get_current_buf()

  vim.bo[edit_buf].buftype = "nofile"
  vim.bo[edit_buf].bufhidden = "wipe"
  vim.bo[edit_buf].swapfile = false
  vim.bo[edit_buf].filetype = "sql"

  -- Seed with a helpful comment
  vim.api.nvim_buf_set_lines(edit_buf, 0, -1, false, {
    string.format("-- Tables: %s, csv  |  Source: %s", alias, vim.fn.fnamemodify(filepath, ":t")),
    string.format("-- Press <C-CR> or <leader>qr to execute"),
    "",
    string.format("SELECT * FROM %s LIMIT 10;", alias),
  })

  -- Place cursor on the SELECT line
  vim.api.nvim_win_set_cursor(0, { 4, 0 })

  -- Keymap to execute the buffer contents as a query
  local function execute()
    local lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false)
    -- Strip comment lines
    local sql_lines = {}
    for _, line in ipairs(lines) do
      if not line:match("^%s*%-%-") then
        sql_lines[#sql_lines + 1] = line
      end
    end
    local sql = table.concat(sql_lines, "\n")
    M.query(sql, buf) -- run against the original CSV buffer
  end

  vim.keymap.set("n", "<C-CR>", execute, { buffer = edit_buf, desc = "Execute SQL query" })
  vim.keymap.set("n", "<leader>qr", execute, { buffer = edit_buf, desc = "Execute SQL query" })
end

--- Get query history.
---@return string[]
function M.get_history()
  return vim.deepcopy(history)
end

return M

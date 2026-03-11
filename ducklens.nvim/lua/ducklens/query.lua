local duckdb = require("ducklens.duckdb")
local display = require("ducklens.display")
local formats = require("ducklens.formats")

local M = {}

---@type string[] command history
local history = {}

--- Build SQL that creates view aliases for the file, then runs the user query.
---@param filepath string
---@return string sql_prefix
---@return string alias  clean table name
---@return string|nil error
local function wrap_query(filepath, user_sql)
  local reader, fmt, err = formats.reader_expr(filepath)
  if err then
    return "", "", err
  end

  local basename = vim.fn.fnamemodify(filepath, ":t:r")
  local alias = basename:gsub("[^%w_]", "_"):lower()

  -- Create views so the user can reference by clean name or generic "data"
  local sql = string.format([[
CREATE OR REPLACE VIEW "%s" AS SELECT * FROM %s;
CREATE OR REPLACE VIEW data AS SELECT * FROM "%s";
%s
]], alias, reader, alias, user_sql)

  return sql, alias, nil
end

--- Execute a SQL query against the current buffer's file.
---@param sql string  user-provided SQL
---@param buf? number
function M.query(sql, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    vim.notify("ducklens: Buffer has no file path. Save the file first.", vim.log.levels.ERROR)
    return
  end

  if sql == "" then
    vim.notify("ducklens: No SQL provided.", vim.log.levels.WARN)
    return
  end

  history[#history + 1] = sql

  vim.notify("ducklens: Running query...", vim.log.levels.INFO)

  local full_sql, _, err = wrap_query(filepath, sql)
  if err then
    vim.notify("ducklens: " .. err, vim.log.levels.ERROR)
    return
  end

  duckdb.run_async(full_sql, {}, function(stdout, stderr, code)
    if code ~= 0 then
      vim.notify("ducklens: Query error:\n" .. stderr, vim.log.levels.ERROR)
      return
    end

    if stdout == "" or stdout:match("^%s*$") then
      vim.notify("ducklens: Query returned no output.", vim.log.levels.INFO)
      return
    end

    local ok, rows = pcall(vim.json.decode, stdout)
    if ok and type(rows) == "table" and #rows > 0 then
      display.show_results(rows, sql)
    else
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
  local fmt = formats.detect(filepath)
  local fmt_label = fmt and fmt.name or "?"

  vim.ui.input({
    prompt = string.format("SQL [%s] (tables: %s, data)> ", fmt_label, alias),
    completion = "file",
  }, function(input)
    if input and input ~= "" then
      M.query(input, buf)
    end
  end)
end

--- Open a scratch buffer for multi-line SQL editing.
---@param buf? number
function M.editor(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local basename = vim.fn.fnamemodify(filepath, ":t:r")
  local alias = basename:gsub("[^%w_]", "_"):lower()
  local fmt = formats.detect(filepath)
  local fmt_label = fmt and fmt.name or "?"

  vim.cmd("botright 12new")
  local edit_buf = vim.api.nvim_get_current_buf()

  vim.bo[edit_buf].buftype = "nofile"
  vim.bo[edit_buf].bufhidden = "wipe"
  vim.bo[edit_buf].swapfile = false
  vim.bo[edit_buf].filetype = "sql"

  vim.api.nvim_buf_set_lines(edit_buf, 0, -1, false, {
    string.format("-- [%s] Tables: %s, data  |  Source: %s", fmt_label, alias, vim.fn.fnamemodify(filepath, ":t")),
    "-- Press <C-CR> or <leader>qr to execute",
    "",
    string.format("SELECT * FROM %s LIMIT 10;", alias),
  })

  vim.api.nvim_win_set_cursor(0, { 4, 0 })

  local function execute()
    local lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false)
    local sql_lines = {}
    for _, line in ipairs(lines) do
      if not line:match("^%s*%-%-") then
        sql_lines[#sql_lines + 1] = line
      end
    end
    local sql = table.concat(sql_lines, "\n")
    M.query(sql, buf)
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

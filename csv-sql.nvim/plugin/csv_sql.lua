if vim.g.loaded_csv_sql then
  return
end
vim.g.loaded_csv_sql = true

local csvsql = require("csv-sql")

-- Health check
vim.api.nvim_create_user_command("CsvSqlCheck", function()
  csvsql.check_health()
end, { desc = "Check DuckDB availability" })

-- Type analysis
vim.api.nvim_create_user_command("CsvSqlAnalyze", function()
  csvsql.analyze()
end, { desc = "Infer SQL column types for the current CSV" })

-- DDL generation
vim.api.nvim_create_user_command("CsvSqlDDL", function()
  csvsql.generate_ddl()
end, { desc = "Generate CREATE TABLE from inferred types" })

-- Run inline SQL
vim.api.nvim_create_user_command("CsvSqlQuery", function(opts)
  csvsql.query(opts.args)
end, {
  nargs = "+",
  desc = "Run a SQL query against the current CSV",
})

-- Interactive prompt
vim.api.nvim_create_user_command("CsvSqlPrompt", function()
  csvsql.prompt()
end, { desc = "Open SQL query prompt" })

-- Multi-line SQL editor
vim.api.nvim_create_user_command("CsvSqlEditor", function()
  csvsql.editor()
end, { desc = "Open multi-line SQL editor for the current CSV" })

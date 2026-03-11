if vim.g.loaded_ducklens then
  return
end
vim.g.loaded_ducklens = true

local dl = require("ducklens")

vim.api.nvim_create_user_command("DuckLensCheck", function()
  dl.check_health()
end, { desc = "Check DuckDB availability" })

vim.api.nvim_create_user_command("DuckLensFormats", function()
  dl.supported()
end, { desc = "List supported file formats" })

vim.api.nvim_create_user_command("DuckLensAnalyze", function()
  dl.analyze()
end, { desc = "Infer SQL column types for the current file" })

vim.api.nvim_create_user_command("DuckLensDDL", function()
  dl.generate_ddl()
end, { desc = "Generate CREATE TABLE from inferred types" })

vim.api.nvim_create_user_command("DuckLensQuery", function(opts)
  dl.query(opts.args)
end, {
  nargs = "+",
  desc = "Run a SQL query against the current file",
})

vim.api.nvim_create_user_command("DuckLensPrompt", function()
  dl.prompt()
end, { desc = "Open SQL query prompt" })

vim.api.nvim_create_user_command("DuckLensEditor", function()
  dl.editor()
end, { desc = "Open multi-line SQL editor for the current file" })

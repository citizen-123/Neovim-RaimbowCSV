if vim.g.loaded_rainbow_csv then
  return
end
vim.g.loaded_rainbow_csv = true

local rc = require("rainbow-csv")

-- User commands
vim.api.nvim_create_user_command("RainbowCsvToggle", function()
  rc.toggle()
end, { desc = "Toggle rainbow column highlighting" })

vim.api.nvim_create_user_command("RainbowCsvEnable", function()
  rc.enable()
end, { desc = "Enable rainbow column highlighting" })

vim.api.nvim_create_user_command("RainbowCsvDisable", function()
  rc.disable()
end, { desc = "Disable rainbow column highlighting" })

vim.api.nvim_create_user_command("RainbowCsvAlignCycle", function()
  rc.cycle_align()
end, { desc = "Cycle alignment: none → virtual → inplace → none" })

vim.api.nvim_create_user_command("RainbowCsvAlignVirtual", function()
  rc.set_align("virtual")
end, { desc = "Align columns with virtual text (non-destructive)" })

vim.api.nvim_create_user_command("RainbowCsvAlignInplace", function()
  rc.set_align("inplace")
end, { desc = "Align columns in-place (modifies buffer)" })

vim.api.nvim_create_user_command("RainbowCsvAlignOff", function()
  rc.set_align("none")
end, { desc = "Remove column alignment" })

vim.api.nvim_create_user_command("RainbowCsvColumnInfo", function()
  rc.column_info()
end, { desc = "Show current column name and index" })

vim.api.nvim_create_user_command("RainbowCsvSetDelim", function(opts)
  local delim_map = { comma = ",", tab = "\t", pipe = "|" }
  local d = delim_map[opts.args] or opts.args
  if d == "" then
    vim.notify("Usage: :RainbowCsvSetDelim <comma|tab|pipe|char>", vim.log.levels.ERROR)
    return
  end
  rc.set_delimiter(d)
end, {
  nargs = 1,
  complete = function()
    return { "comma", "tab", "pipe" }
  end,
  desc = "Override detected delimiter",
})

vim.api.nvim_create_user_command("RainbowCsvSetHeaderRow", function(opts)
  local row = tonumber(opts.args)
  if not row then
    vim.notify("Usage: :RainbowCsvSetHeaderRow <line_number>", vim.log.levels.ERROR)
    return
  end
  rc.set_header_row(row)
end, {
  nargs = 1,
  desc = "Set which line contains column headers (1-indexed)",
})

vim.api.nvim_create_user_command("RainbowCsvNoHeader", function()
  rc.no_header()
end, { desc = "Treat file as headerless — column_info shows index only" })

-- Auto-enable on CSV/TSV files
local augroup = vim.api.nvim_create_augroup("RainbowCsv", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = { "*.csv", "*.tsv", "*.psv" },
  callback = function(ev)
    rc.enable(ev.buf)
  end,
})

-- Refresh highlights on text changes (debounced)
local refresh_timer = nil
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = augroup,
  pattern = { "*.csv", "*.tsv", "*.psv" },
  callback = function(ev)
    if refresh_timer then
      refresh_timer:stop()
    end
    refresh_timer = vim.defer_fn(function()
      rc.refresh(ev.buf)
      refresh_timer = nil
    end, 200)
  end,
})

-- Clean up state when buffer is deleted
vim.api.nvim_create_autocmd("BufDelete", {
  group = augroup,
  callback = function(ev)
    -- Let gc handle it; just a minor cleanup hook
  end,
})

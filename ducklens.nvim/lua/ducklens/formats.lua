local M = {}

---@class DuckLensFormat
---@field name string        human-readable name
---@field reader string      DuckDB reader function name
---@field opts string        default reader options
---@field extensions string[] file extensions (lowercase, no dot)

---@type DuckLensFormat[]
M.formats = {
  {
    name = "CSV",
    reader = "read_csv",
    opts = "auto_detect=true, header=true",
    extensions = { "csv" },
  },
  {
    name = "TSV",
    reader = "read_csv",
    opts = "auto_detect=true, header=true, delim='\\t'",
    extensions = { "tsv" },
  },
  {
    name = "PSV",
    reader = "read_csv",
    opts = "auto_detect=true, header=true, delim='|'",
    extensions = { "psv" },
  },
  {
    name = "JSON",
    reader = "read_json",
    opts = "auto_detect=true",
    extensions = { "json" },
  },
  {
    name = "JSONL",
    reader = "read_json",
    opts = "auto_detect=true, format='newline_delimited'",
    extensions = { "jsonl", "ndjson" },
  },
  {
    name = "Parquet",
    reader = "read_parquet",
    opts = "",
    extensions = { "parquet", "pq" },
  },
}

--- Build a DuckDB reader expression for a file path.
---@param filepath string
---@param format? DuckLensFormat  override auto-detection
---@return string expression  e.g. "read_csv('/path/to/file.csv', auto_detect=true)"
---@return DuckLensFormat format  the matched or provided format
---@return string|nil error
function M.reader_expr(filepath, format)
  if not format then
    format = M.detect(filepath)
  end

  if not format then
    return "", {}, "Could not detect format for: " .. filepath
  end

  local escaped = filepath:gsub("'", "''")
  local opts_str = format.opts ~= "" and (", " .. format.opts) or ""
  local expr = string.format("%s('%s'%s)", format.reader, escaped, opts_str)

  return expr, format, nil
end

--- Detect format from file extension.
---@param filepath string
---@return DuckLensFormat|nil
function M.detect(filepath)
  local ext = filepath:match("%.([^%.]+)$")
  if not ext then
    return nil
  end
  ext = ext:lower()

  for _, fmt in ipairs(M.formats) do
    for _, fext in ipairs(fmt.extensions) do
      if ext == fext then
        return fmt
      end
    end
  end

  return nil
end

--- Get a sorted list of all supported extensions.
---@return string[]
function M.supported_extensions()
  local exts = {}
  for _, fmt in ipairs(M.formats) do
    for _, ext in ipairs(fmt.extensions) do
      exts[#exts + 1] = ext
    end
  end
  table.sort(exts)
  return exts
end

--- Get format by name (case-insensitive).
---@param name string
---@return DuckLensFormat|nil
function M.by_name(name)
  local upper = name:upper()
  for _, fmt in ipairs(M.formats) do
    if fmt.name:upper() == upper then
      return fmt
    end
  end
  return nil
end

return M

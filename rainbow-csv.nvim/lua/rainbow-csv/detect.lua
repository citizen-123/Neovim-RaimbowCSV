local M = {}

local DELIMITERS = { ",", "\t", "|" }
local DELIMITER_NAMES = { [","] = "comma", ["\t"] = "tab", ["|"] = "pipe" }

--- Score a delimiter by counting occurrences per line across the first N lines.
--- A good delimiter appears consistently (low variance, non-zero count).
---@param lines string[]
---@param delim string
---@return number score (higher = more likely)
local function score_delimiter(lines, delim)
  local counts = {}
  for _, line in ipairs(lines) do
    local n = 0
    -- For comma/pipe, simple count. For tab, gsub works fine.
    for _ in line:gmatch(vim.pesc(delim)) do
      n = n + 1
    end
    counts[#counts + 1] = n
  end

  if #counts == 0 then
    return -1
  end

  -- Mean
  local sum = 0
  for _, c in ipairs(counts) do
    sum = sum + c
  end
  local mean = sum / #counts

  if mean == 0 then
    return -1
  end

  -- Variance
  local var_sum = 0
  for _, c in ipairs(counts) do
    var_sum = var_sum + (c - mean) ^ 2
  end
  local variance = var_sum / #counts

  -- High mean + low variance = good candidate.
  -- Normalize variance by mean to get coefficient of variation.
  local cv = (variance > 0) and (math.sqrt(variance) / mean) or 0
  return mean / (1 + cv)
end

--- Detect the most likely delimiter from buffer lines.
---@param buf number
---@return string delimiter
---@return string name
function M.detect(buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local sample_end = math.min(line_count, 30)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, sample_end, false)

  local best_delim = ","
  local best_score = -1

  for _, delim in ipairs(DELIMITERS) do
    local s = score_delimiter(lines, delim)
    if s > best_score then
      best_score = s
      best_delim = delim
    end
  end

  return best_delim, DELIMITER_NAMES[best_delim] or "unknown"
end

return M

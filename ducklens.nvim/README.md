# ducklens.nvim

SQL type inference and interactive querying for structured data files in Neovim, powered by DuckDB.

Works with CSV, TSV, JSON, JSONL, and Parquet out of the box.

## Requirements

- Neovim ≥ 0.10
- [DuckDB CLI](https://duckdb.org/docs/installation) on your `$PATH` (or set `g:ducklens_duckdb_path`)

## Install

```sh
git clone https://github.com/citizen-123/Neovim-RaimbowCSV.git
cd Neovim-RaimbowCSV

# Linux/macOS
bash install.sh --only ducklens

# Windows PowerShell
.\install.ps1 -Only ducklens
```

Or manually copy `ducklens.nvim/` into your Neovim pack directory.

Verify DuckDB is found:

```vim
:DuckLensCheck
```

## Supported Formats

| Format  | Extensions         | DuckDB Reader  |
|---------|--------------------|----------------|
| CSV     | `.csv`             | `read_csv`     |
| TSV     | `.tsv`             | `read_csv`     |
| PSV     | `.psv`             | `read_csv`     |
| JSON    | `.json`            | `read_json`    |
| JSONL   | `.jsonl`, `.ndjson` | `read_json`   |
| Parquet | `.parquet`, `.pq`  | `read_parquet` |

## Commands

| Command | Description |
|---|---|
| `:DuckLensCheck` | Verify DuckDB is available |
| `:DuckLensFormats` | List supported file formats |
| `:DuckLensAnalyze` | Infer SQL types for each column and display in a split |
| `:DuckLensDDL` | Generate a `CREATE TABLE` statement from inferred types |
| `:DuckLensQuery <sql>` | Run SQL inline |
| `:DuckLensPrompt` | Open a `vim.ui.input` prompt for a query |
| `:DuckLensEditor` | Open a scratch SQL buffer with `<C-CR>` / `<leader>qr` to execute |

## Table Aliases

Two views are created automatically for every query:

- **`data`** — generic alias, works on any file
- **`<filename>`** — derived from the buffer's filename (e.g. `events` for `events.json`)

Examples:

```sql
SELECT * FROM data LIMIT 5;
SELECT type, count(*) FROM events GROUP BY type;
SELECT region, sum(revenue) FROM sales_2024 WHERE quarter = 'Q3' GROUP BY region;
```

## JSON-Specific Notes

DuckDB infers nested JSON structures as `STRUCT` and `MAP` types. The DDL generator maps these to `JSONB` for portability. For nested access in queries, DuckDB supports dot notation and bracket indexing:

```sql
-- Dot notation for known keys
SELECT data.user.name FROM events LIMIT 5;

-- Bracket indexing for dynamic access
SELECT data['user']['name'] FROM events LIMIT 5;

-- Unnest arrays
SELECT unnest(tags) AS tag, count(*) FROM data GROUP BY tag;
```

## Suggested Keybindings

```lua
vim.keymap.set("n", "<leader>da", "<cmd>DuckLensAnalyze<cr>", { desc = "DuckLens analyze types" })
vim.keymap.set("n", "<leader>dd", "<cmd>DuckLensDDL<cr>", { desc = "DuckLens generate DDL" })
vim.keymap.set("n", "<leader>dq", "<cmd>DuckLensPrompt<cr>", { desc = "DuckLens query prompt" })
vim.keymap.set("n", "<leader>de", "<cmd>DuckLensEditor<cr>", { desc = "DuckLens SQL editor" })
```

## API

```lua
local dl = require("ducklens")

dl.analyze(buf?)
dl.generate_ddl(buf?)
dl.query(sql, buf?)
dl.prompt(buf?)
dl.editor(buf?)
dl.check_health()
dl.supported()
dl.get_types(filepath)        -- returns table[], synchronous
dl.duckdb_to_sql(duck_type)   -- type mapping helper
dl.detect_format(filepath)    -- returns format table or nil
dl.formats                    -- access the formats module directly
```

## Type Mapping

| DuckDB | SQL Output |
|---|---|
| VARCHAR | TEXT |
| BIGINT | BIGINT |
| INTEGER | INTEGER |
| DOUBLE | DOUBLE PRECISION |
| BOOLEAN | BOOLEAN |
| DATE | DATE |
| TIMESTAMP | TIMESTAMP |
| JSON | JSONB |
| STRUCT(...) | JSONB |
| LIST / arrays | JSONB |
| HUGEINT | NUMERIC(38,0) |

Custom mappings can be extended by overriding `dl.duckdb_to_sql`.

# csv-sql.nvim

SQL type inference and interactive querying for CSV files in Neovim, powered by DuckDB.

## Requirements

- Neovim ≥ 0.10
- [DuckDB CLI](https://duckdb.org/docs/installation) on your `$PATH` (or set `g:csvsql_duckdb_path`)

## Install

Clone or symlink into your runtimepath:

```sh
git clone https://github.com/youruser/Neovim-RaimbowCSV.git
# Use the install scripts at the repo root, or manually:
cp -r csv-sql.nvim ~/.config/nvim/pack/plugins/start/csv-sql.nvim
```

Verify DuckDB is found:

```vim
:CsvSqlCheck
```

## Commands

| Command | Description |
|---|---|
| `:CsvSqlCheck` | Verify DuckDB is available |
| `:CsvSqlAnalyze` | Infer SQL types for each column and display in a split |
| `:CsvSqlDDL` | Generate a `CREATE TABLE` statement from inferred types |
| `:CsvSqlQuery <sql>` | Run SQL inline (e.g. `:CsvSqlQuery SELECT count(*) FROM csv`) |
| `:CsvSqlPrompt` | Open a `vim.ui.input` prompt for a query |
| `:CsvSqlEditor` | Open a scratch SQL buffer with `<C-CR>` / `<leader>qr` to execute |

## Table Aliases

When you run a query, two views are created automatically:

- **`csv`** — always available as a generic alias
- **`<filename>`** — derived from the buffer's filename (e.g. `sales_2024` for `sales_2024.csv`)

So all of these work:

```sql
SELECT * FROM csv LIMIT 5;
SELECT region, sum(revenue) FROM sales_2024 GROUP BY region;
```

## Suggested Keybindings

```lua
vim.keymap.set("n", "<leader>sa", "<cmd>CsvSqlAnalyze<cr>", { desc = "Analyze CSV types" })
vim.keymap.set("n", "<leader>sd", "<cmd>CsvSqlDDL<cr>", { desc = "Generate DDL" })
vim.keymap.set("n", "<leader>sq", "<cmd>CsvSqlPrompt<cr>", { desc = "SQL query prompt" })
vim.keymap.set("n", "<leader>se", "<cmd>CsvSqlEditor<cr>", { desc = "SQL editor" })
```

## API

```lua
local csvsql = require("csv-sql")
csvsql.analyze(buf?)
csvsql.generate_ddl(buf?)
csvsql.query(sql, buf?)
csvsql.prompt(buf?)
csvsql.editor(buf?)
csvsql.check_health()
csvsql.get_types(filepath)       -- returns table[], synchronous
csvsql.duckdb_to_sql(duck_type)  -- type mapping helper
```

## Type Mapping

DuckDB's inferred types are mapped to standard SQL types:

| DuckDB | SQL Output |
|---|---|
| VARCHAR | TEXT |
| BIGINT | BIGINT |
| INTEGER | INTEGER |
| DOUBLE | DOUBLE PRECISION |
| BOOLEAN | BOOLEAN |
| DATE | DATE |
| TIMESTAMP | TIMESTAMP |
| HUGEINT | NUMERIC(38,0) |

Custom mappings can be extended by overriding `csvsql.duckdb_to_sql`.

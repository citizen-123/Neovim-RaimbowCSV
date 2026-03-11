# Neovim CSV Plugins

Two Neovim plugins for working with delimited data files.

## Plugins

### [rainbow-csv.nvim](rainbow-csv.nvim/)

Rainbow column highlighting and alignment for CSV, TSV, and pipe-delimited files. Colors each column distinctly, auto-detects delimiters, and supports virtual or in-place column alignment.

### [csv-sql.nvim](csv-sql.nvim/)

SQL type inference and interactive querying for CSV files, powered by DuckDB. Analyze column types, generate DDL, and run SQL queries against any CSV directly from Neovim.

## Install

### Both plugins (recommended)

```sh
git clone https://github.com/citizen-123/Neovim-RaimbowCSV.git
cd Neovim-RaimbowCSV

# Linux/macOS
bash install.sh

# Windows (PowerShell)
.\install.ps1
```

### Single plugin

```sh
# Linux/macOS — install just one
bash install.sh --only rainbow-csv
bash install.sh --only csv-sql

# Windows
.\install.ps1 -Only rainbow-csv
.\install.ps1 -Only csv-sql
```

## Requirements

- Neovim ≥ 0.10
- [DuckDB CLI](https://duckdb.org/docs/installation) (for csv-sql.nvim only)

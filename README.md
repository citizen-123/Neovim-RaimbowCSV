# Neovim CSV Plugins

Two Neovim plugins for working with structured data files.

## Plugins

### [rainbow-csv.nvim](rainbow-csv.nvim/)

Rainbow column highlighting and alignment for CSV, TSV, and pipe-delimited files. Colors each column distinctly, auto-detects delimiters, and supports virtual or in-place column alignment.

### [ducklens.nvim](ducklens.nvim/)

SQL type inference and interactive querying for structured data files (CSV, TSV, JSON, JSONL, Parquet), powered by DuckDB. Analyze column types, generate DDL, and run SQL queries directly from Neovim.

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
# Linux/macOS
bash install.sh --only rainbow-csv
bash install.sh --only ducklens

# Windows
.\install.ps1 -Only rainbow-csv
.\install.ps1 -Only ducklens
```

## Requirements

- Neovim ≥ 0.10
- [DuckDB CLI](https://duckdb.org/docs/installation) (for ducklens.nvim only)

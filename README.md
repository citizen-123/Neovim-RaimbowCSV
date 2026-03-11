# rainbow-csv.nvim

Rainbow column highlighting and alignment for CSV, TSV, and pipe-delimited files in Neovim.

## Requirements

- Neovim ≥ 0.10 (for inline virtual text support)

## Install

Clone or symlink into your runtimepath:

```sh
git clone https://github.com/youruser/rainbow-csv.nvim \
  ~/.config/nvim/pack/plugins/start/rainbow-csv.nvim
```

Or if you manage your runtimepath manually, add to `init.lua`:

```lua
vim.opt.runtimepath:append("/path/to/rainbow-csv.nvim")
```

No `setup()` call required — the plugin auto-enables on `.csv`, `.tsv`, and `.psv` files.

## Commands

| Command | Description |
|---|---|
| `:RainbowCsvToggle` | Toggle column highlighting |
| `:RainbowCsvEnable` | Enable highlighting |
| `:RainbowCsvDisable` | Disable highlighting |
| `:RainbowCsvAlignCycle` | Cycle: none → virtual → inplace → none |
| `:RainbowCsvAlignVirtual` | Align with virtual text (buffer unchanged) |
| `:RainbowCsvAlignInplace` | Align by padding fields (modifies buffer) |
| `:RainbowCsvAlignOff` | Remove alignment |
| `:RainbowCsvColumnInfo` | Show column name/index at cursor |
| `:RainbowCsvSetDelim <d>` | Override delimiter (`comma`, `tab`, `pipe`, or any char) |
| `:RainbowCsvSetHeaderRow <n>` | Set which line contains headers (1-indexed, default 1) |
| `:RainbowCsvNoHeader` | Headerless mode — `column_info` shows index only |

## Suggested Keybindings

```lua
vim.keymap.set("n", "<leader>cr", "<cmd>RainbowCsvToggle<cr>", { desc = "Toggle rainbow CSV" })
vim.keymap.set("n", "<leader>ca", "<cmd>RainbowCsvAlignCycle<cr>", { desc = "Cycle CSV alignment" })
vim.keymap.set("n", "<leader>ci", "<cmd>RainbowCsvColumnInfo<cr>", { desc = "CSV column info" })
```

## How It Works

**Delimiter detection** samples the first 30 lines, scores each candidate delimiter (`,`, `\t`, `|`) by consistency across rows, and picks the best match.

**Column highlighting** uses extmarks to color each column with a distinct highlight group (10 colors, cycling). Delimiters are dimmed to reduce visual noise.

**Virtual alignment** inserts inline virtual text (padding spaces) before delimiters so columns line up visually. The buffer content stays untouched. Requires Neovim 0.10+.

**In-place alignment** pads fields with real spaces and adds a space after each delimiter. This modifies the buffer — use undo (`u`) to revert if needed.

## API

All functions are available via `require("rainbow-csv")`:

```lua
local rc = require("rainbow-csv")
rc.enable(buf?)
rc.disable(buf?)
rc.toggle(buf?)
rc.cycle_align(buf?)
rc.set_align("none"|"virtual"|"inplace", buf?)
rc.set_delimiter(","|"\t"|"|"|string, buf?)
rc.column_info(buf?)
rc.set_header_row(row, buf?)
rc.no_header(buf?)
rc.refresh(buf?)
```

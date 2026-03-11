#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="rainbow-csv.nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine install target
if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" ]]; then
  PACK_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/plugins/start"
elif [[ -d "$HOME/.config/nvim" ]]; then
  PACK_DIR="$HOME/.config/nvim/pack/plugins/start"
else
  echo "Could not locate a Neovim config directory."
  echo "Ensure Neovim is installed and ~/.config/nvim or \$XDG_DATA_HOME/nvim exists."
  exit 1
fi

TARGET="$PACK_DIR/$PLUGIN_NAME"

echo "Installing $PLUGIN_NAME"
echo "  Source:  $SCRIPT_DIR"
echo "  Target:  $TARGET"

# Remove previous install if present
if [[ -d "$TARGET" ]]; then
  echo "  Removing existing installation..."
  rm -rf "$TARGET"
fi

# Create pack directory if needed
mkdir -p "$PACK_DIR"

# Copy plugin files
cp -r "$SCRIPT_DIR" "$TARGET"

# Clean up non-plugin files from the installed copy
rm -f "$TARGET/install.sh" "$TARGET/install.ps1"

echo ""
echo "Done. Restart Neovim or run :packloadall to activate."
echo "The plugin auto-enables on .csv, .tsv, and .psv files."
echo "For other files, run :RainbowCsvEnable manually."

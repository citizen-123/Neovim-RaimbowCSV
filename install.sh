#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS=("rainbow-csv.nvim" "csv-sql.nvim")
ONLY=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      ONLY="$2.nvim"
      shift 2
      ;;
    --only=*)
      ONLY="${1#--only=}.nvim"
      shift
      ;;
    -h|--help)
      echo "Usage: install.sh [--only <rainbow-csv|csv-sql>]"
      echo "  --only    Install a single plugin instead of both"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Determine pack directory
if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" ]]; then
  PACK_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/plugins/start"
elif [[ -d "$HOME/.config/nvim" ]]; then
  PACK_DIR="$HOME/.config/nvim/pack/plugins/start"
else
  echo "Could not locate a Neovim config directory."
  echo "Ensure Neovim is installed and ~/.config/nvim or \$XDG_DATA_HOME/nvim exists."
  exit 1
fi

mkdir -p "$PACK_DIR"

install_plugin() {
  local name="$1"
  local src="$SCRIPT_DIR/$name"
  local dest="$PACK_DIR/$name"

  if [[ ! -d "$src" ]]; then
    echo "Plugin directory not found: $src"
    return 1
  fi

  echo "Installing $name"
  echo "  Source:  $src"
  echo "  Target:  $dest"

  if [[ -d "$dest" ]]; then
    echo "  Removing existing installation..."
    rm -rf "$dest"
  fi

  cp -r "$src" "$dest"
  echo "  Done."
  echo ""
}

if [[ -n "$ONLY" ]]; then
  install_plugin "$ONLY"
else
  for plugin in "${PLUGINS[@]}"; do
    install_plugin "$plugin"
  done
fi

echo "Restart Neovim or run :packloadall to activate."

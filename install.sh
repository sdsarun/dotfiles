#!/usr/bin/env bash
set -euo pipefail

DOTVERSE="${DOTVERSE:-$HOME/.dotverse}"

link_config() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  ln -sf "$source" "$target"
}

link_config "$DOTVERSE/zsh/.zshrc" "$HOME/.zshrc"
link_config "$DOTVERSE/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_config "$DOTVERSE/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"

case "$(uname -s)" in
  Darwin|Linux)
    ZED_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zed"
    link_config "$DOTVERSE/zed/settings.json" "$ZED_CONFIG_DIR/settings.json"
    link_config "$DOTVERSE/zed/keymap.json" "$ZED_CONFIG_DIR/keymap.json"
    ;;
  *)
    printf 'Skipping Zed symlinks: unsupported platform (%s)\n' "$(uname -s)" >&2
    ;;
esac

echo "Symlinks created successfully!"

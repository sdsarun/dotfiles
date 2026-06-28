#!/usr/bin/env bash
set -euo pipefail

DOTVERSE="${DOTVERSE:-$HOME/.dotverse}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

# ── Symlink table ─────────────────────────────────────────────────────────────
# Format: "repo_subpath|target_path"
# To add a new tool: append one line to the right array, nothing else needed.

SYMLINKS=(
  "zsh/.zshrc|$HOME/.zshrc"
  "tmux/.tmux.conf|$HOME/.tmux.conf"
)

DARWIN_SYMLINKS=(
  "zed/settings.json|$CONFIG/zed/settings.json"
  "zed/keymap.json|$CONFIG/zed/keymap.json"
  "nvim|$CONFIG/nvim"
  "ghostty/config|$CONFIG/ghostty/config"
  "gram/settings.jsonc|$CONFIG/gram/settings.jsonc"
  "gram/keymap.jsonc|$CONFIG/gram/keymap.jsonc"
)

# Tools that were removed — prompts user to clean up stale symlinks.
# Format: "target_path|description"
DEPRECATED_SYMLINKS=(
  "$HOME/.wezterm.lua|wezterm"
)

# ── Helpers ───────────────────────────────────────────────────────────────────

expand_path() {
  local path="$1"
  path="${path/#\~/$HOME}"
  path="${path//\$\{HOME\}/$HOME}"
  path="${path//\$HOME/$HOME}"
  printf '%s' "$path"
}

link_config() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf 'Already linked: %s → %s\n' "$source" "$target"
  else
    if [[ -d "$target" && ! -L "$target" ]]; then
      rm -rf "$target"
    fi
    ln -sf "$source" "$target"
    printf 'Linked: %s → %s\n' "$source" "$target"
  fi
}

cleanup_deprecated() {
  local target="$1"
  local description="$2"

  if [[ -L "$target" ]]; then
    printf 'WARNING: Deprecated symlink detected: %s (%s is no longer managed)\n' "$target" "$description"
    read -rp "Are you sure you want to remove this symlink? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm "$target"
      printf 'Removed: %s\n' "$target"
    else
      printf 'Skipped (kept): %s\n' "$target"
    fi
  fi
}

ensure_git_clone() {
  local repo_url="$1"
  local destination="$2"
  local label="$3"

  if [[ -d "$destination" ]]; then
    printf '%s already present at %s\n' "$label" "$destination"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    printf 'Cannot clone %s: git is not installed or not in PATH\n' "$label" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$destination")"
  git clone "$repo_url" "$destination"
  printf 'Cloned: %s → %s\n' "$label" "$destination"
}

setup_zsh_dependencies() {
  local zshrc_path="$DOTVERSE/zsh/.zshrc"
  local zsh_dir=""

  if [[ -f "$zshrc_path" ]]; then
    zsh_dir="$(awk -F'"' '/^export[[:space:]]+ZSH=/{print $2; exit}' "$zshrc_path")"
    if [[ -z "$zsh_dir" ]]; then
      zsh_dir="$(awk -F'=' '/^export[[:space:]]+ZSH=/{val=$2; gsub(/^[[:space:]]+/,"",val); gsub(/"/,"",val); print val; exit}' "$zshrc_path")"
    fi
  fi

  zsh_dir="${zsh_dir:-$HOME/.oh-my-zsh}"
  zsh_dir="$(expand_path "$zsh_dir")"

  ensure_git_clone "https://github.com/ohmyzsh/ohmyzsh.git" "$zsh_dir" "oh-my-zsh"

  local autosuggestions_dir="$zsh_dir/custom/plugins/zsh-autosuggestions"
  ensure_git_clone "https://github.com/zsh-users/zsh-autosuggestions.git" "$autosuggestions_dir" "zsh-autosuggestions plugin"
}

# ── Deprecated cleanup ────────────────────────────────────────────────────────

for entry in "${DEPRECATED_SYMLINKS[@]}"; do
  cleanup_deprecated "${entry%%|*}" "${entry##*|}"
done

# ── Symlinks ──────────────────────────────────────────────────────────────────

for entry in "${SYMLINKS[@]}"; do
  link_config "$DOTVERSE/${entry%%|*}" "${entry##*|}"
done

case "$(uname -s)" in
  Darwin|Linux)
    for entry in "${DARWIN_SYMLINKS[@]}"; do
      link_config "$DOTVERSE/${entry%%|*}" "${entry##*|}"
    done
    ;;
  *)
    printf 'Skipping platform symlinks: unsupported platform (%s)\n' "$(uname -s)" >&2
    ;;
esac

setup_zsh_dependencies

echo "Symlinks created successfully!"

#!/usr/bin/env bash
set -euo pipefail

DOTVERSE="${DOTVERSE:-$HOME/.dotverse}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

YES=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=true ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
  BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
  CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'
else
  BOLD=''; DIM=''; RESET=''; CYAN=''; GREEN=''; YELLOW=''
fi

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
  local source="$1" target="$2"
  local name="${source##*/}"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf "  ${DIM}◇  %-18s  already linked${RESET}\n" "$name"
  else
    [[ -d "$target" && ! -L "$target" ]] && rm -rf "$target"
    ln -sf "$source" "$target"
    printf "  ${GREEN}◆${RESET}  %-18s  ${DIM}→ %s${RESET}\n" "$name" "$target"
  fi
}

# Populated by pick_symlinks; avoids process substitution so the picker can
# write directly to the terminal.
_SELECTED=()

pick_symlinks() {
  local -a entries=("$@")
  local n=${#entries[@]}
  _SELECTED=()

  if [[ "$YES" == true || ! -t 0 || ! -t 1 ]]; then
    _SELECTED=("${entries[@]}")
    return
  fi

  # Build display labels from "src|tgt" entries
  local -a labels=()
  for entry in "${entries[@]}"; do
    local src="${entry%%|*}" tgt="${entry##*|}"
    local name="${src%%/*}"
    labels+=("$(printf '%-10s  %s' "$name" "$tgt")")
  done

  local cur=0
  local -a sel=()
  for i in "${!entries[@]}"; do sel[i]=1; done

  printf '%s\n' "  ${BOLD}◆${RESET}  ${BOLD}Which configs do you want to install?${RESET}"
  printf '%s\n' "     ${DIM}↑/↓ navigate · space toggle · a all/none · enter confirm · q quit${RESET}"
  printf '\n'

  # Print initial state (n lines + 1 blank)
  for i in "${!entries[@]}"; do
    if [[ $i -eq $cur ]]; then
      if [[ ${sel[$i]} -eq 1 ]]; then
        printf '%s\n' "  ${CYAN}❯${RESET} ${GREEN}◆${RESET}  ${BOLD}${labels[$i]}${RESET}"
      else
        printf '%s\n' "  ${CYAN}❯${RESET} ${DIM}◇${RESET}  ${BOLD}${labels[$i]}${RESET}"
      fi
    else
      if [[ ${sel[$i]} -eq 1 ]]; then
        printf '%s\n' "    ${GREEN}◆${RESET}  ${labels[$i]}"
      else
        printf '%s\n' "    ${DIM}◇${RESET}  ${labels[$i]}"
      fi
    fi
  done
  printf '\n'

  tput civis 2>/dev/null
  trap 'tput cnorm 2>/dev/null' EXIT INT TERM

  local key rest
  while true; do
    tput cuu $((n + 1)) 2>/dev/null

    for i in "${!entries[@]}"; do
      if [[ $i -eq $cur ]]; then
        if [[ ${sel[$i]} -eq 1 ]]; then
          printf '%s\033[K\n' "  ${CYAN}❯${RESET} ${GREEN}◆${RESET}  ${BOLD}${labels[$i]}${RESET}"
        else
          printf '%s\033[K\n' "  ${CYAN}❯${RESET} ${DIM}◇${RESET}  ${BOLD}${labels[$i]}${RESET}"
        fi
      else
        if [[ ${sel[$i]} -eq 1 ]]; then
          printf '%s\033[K\n' "    ${GREEN}◆${RESET}  ${labels[$i]}"
        else
          printf '%s\033[K\n' "    ${DIM}◇${RESET}  ${labels[$i]}"
        fi
      fi
    done
    printf '\033[K\n'

    IFS= read -rsn1 key || { tput cnorm 2>/dev/null; exit 0; }

    case "$key" in
      $'\x1b')
        IFS= read -rsn2 -t 0.05 rest || rest=''
        case "$rest" in
          '[A') [[ $cur -gt 0 ]]        && cur=$(( cur - 1 )) || true ;;
          '[B') [[ $cur -lt $((n-1)) ]] && cur=$(( cur + 1 )) || true ;;
        esac
        ;;
      'k') [[ $cur -gt 0 ]]        && cur=$(( cur - 1 )) || true ;;
      'j') [[ $cur -lt $((n-1)) ]] && cur=$(( cur + 1 )) || true ;;
      ' ') sel[cur]=$(( 1 - sel[cur] )) ;;
      'a'|'A')
        local any_off=0
        for v in "${sel[@]}"; do
          if [[ $v -eq 0 ]]; then any_off=1; break; fi
        done
        local nv=$(( any_off ? 1 : 0 ))
        for i in "${!sel[@]}"; do sel[i]=$nv; done
        ;;
      ''|$'\n') break ;;
      'q'|$'\x03')
        tput cnorm 2>/dev/null
        printf '\n  Cancelled.\n\n'
        exit 0
        ;;
    esac
  done

  tput cnorm 2>/dev/null
  printf '\n'

  for i in "${!entries[@]}"; do
    if [[ ${sel[$i]} -eq 1 ]]; then _SELECTED+=("${entries[$i]}"); fi
  done
}

cleanup_deprecated() {
  local target="$1" description="$2"

  [[ ! -L "$target" ]] && return

  printf '\n'
  printf "  ${YELLOW}▲${RESET}  Deprecated: ${BOLD}%s${RESET}\n" "$target"
  printf "     ${DIM}%s is no longer managed${RESET}\n" "$description"
  printf '\n'

  if [[ "$YES" == true ]]; then
    rm "$target"
    printf "  ${GREEN}✔${RESET}  Removed: %s\n\n" "$target"
    return
  fi

  local confirm
  read -rp "     Remove it? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm "$target"
    printf "  ${GREEN}✔${RESET}  Removed: %s\n" "$target"
  else
    printf "  ${DIM}–${RESET}  Kept: %s\n" "$target"
  fi
  printf '\n'
}

ensure_git_clone() {
  local repo_url="$1" destination="$2" label="$3"

  if [[ -d "$destination" ]]; then
    printf "  ${DIM}◇  %-28s  already present${RESET}\n" "$label"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    printf 'Cannot clone %s: git is not installed or not in PATH\n' "$label" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$destination")"
  git clone --quiet "$repo_url" "$destination"
  printf "  ${GREEN}◆${RESET}  %-28s  ${DIM}cloned${RESET}\n" "$label"
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
  ensure_git_clone "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$zsh_dir/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
}

# ── Main ──────────────────────────────────────────────────────────────────────

printf '\n'
printf '  %sdotverse%s  setup\n' "$BOLD" "$RESET"
printf '\n'

# Deprecated cleanup
for entry in "${DEPRECATED_SYMLINKS[@]}"; do
  cleanup_deprecated "${entry%%|*}" "${entry##*|}"
done

# Build list for current platform
all_entries=("${SYMLINKS[@]}")
case "$(uname -s)" in
  Darwin|Linux) all_entries+=("${DARWIN_SYMLINKS[@]}") ;;
  *) printf '  Skipping platform symlinks: unsupported platform (%s)\n\n' "$(uname -s)" >&2 ;;
esac

pick_symlinks "${all_entries[@]}"

if [[ ${#_SELECTED[@]} -eq 0 ]]; then
  printf '%s\n\n' "  ${DIM}Nothing selected.${RESET}"
  exit 0
fi

printf '%s\n\n' "  ${BOLD}Creating symlinks${RESET}"
for entry in "${_SELECTED[@]}"; do
  link_config "$DOTVERSE/${entry%%|*}" "${entry##*|}"
done

printf '\n'
printf '%s\n\n' "  ${BOLD}Zsh dependencies${RESET}"
setup_zsh_dependencies

printf '\n'
printf '%s\n\n' "  ${GREEN}◆${RESET}  ${BOLD}All done!${RESET}"

#!/usr/bin/env bash
set -euo pipefail

DOTVERSE="${DOTVERSE:-$HOME/.dotverse}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

YES=false
MODE=install
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=true ;;
    --unlink) MODE=unlink ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
else
  BOLD=''; DIM=''; RESET=''; CYAN=''; GREEN=''; YELLOW=''
fi

# ── Symlink table ─────────────────────────────────────────────────────────────
# Format: "repo_subpath|target_path"
# To add a new tool: append one line to the right array, nothing else needed.

SYMLINKS=(
  "zsh/.zshrc|$HOME/.zshrc"
  "tmux/.tmux.conf|$HOME/.tmux.conf"
  "wezterm/.wezterm.lua|$HOME/.wezterm.lua"
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
DEPRECATED_SYMLINKS=()

# ── Helpers ───────────────────────────────────────────────────────────────────

expand_path() {
  local path="$1"
  path="${path/#\~/$HOME}"
  path="${path//\$\{HOME\}/$HOME}"
  path="${path//\$HOME/$HOME}"
  printf '%s' "$path"
}

link_state() {
  local source="$1" target="$2"

  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      printf 'linked'
    else
      printf 'foreign'
    fi
  elif [[ -e "$target" ]]; then
    printf 'blocked'
  else
    printf 'missing'
  fi
}

link_config() {
  local source="$1" target="$2"
  local name="${source##*/}"
  local state

  state="$(link_state "$source" "$target")"

  mkdir -p "$(dirname "$target")"
  if [[ "$state" == linked ]]; then
    printf "  ${DIM}◇  %-18s  already linked${RESET}\n" "$name"
  else
    [[ -d "$target" && ! -L "$target" ]] && rm -rf "$target"
    ln -sf "$source" "$target"
    printf "  ${GREEN}◆${RESET}  %-18s  ${DIM}→ %s${RESET}\n" "$name" "$target"
  fi
}

unlink_config() {
  local source="$1" target="$2" name="$3"
  local state

  state="$(link_state "$source" "$target")"
  case "$state" in
    linked)
      rm "$target"
      printf "  ${GREEN}◆${RESET}  %-18s  ${DIM}unlinked${RESET}\n" "$name"
      ;;
    missing)
      printf "  ${DIM}◇  %-18s  not linked${RESET}\n" "$name"
      ;;
    foreign)
      printf "  ${YELLOW}▲${RESET}  %-18s  ${DIM}skipped: different symlink${RESET}\n" "$name"
      ;;
    blocked)
      printf "  ${YELLOW}▲${RESET}  %-18s  ${DIM}skipped: existing path${RESET}\n" "$name"
      ;;
  esac
}

# Populated by pick_symlinks; avoids process substitution so the picker can
# write directly to the terminal.
_SELECTED=()
_PICKER_CANCELLED=false
_PICKER_ENTRIES=()
_PICKER_SELECTION=()
_PICKER_MODE=install
_PICKER_CUR=0
_PICKER_VIEW_START=0
_PICKER_VIEW_END=0
_PICKER_MAX_ROWS=0
_PICKER_COLS=0
_PICKER_LINES=0
_PICKER_RENDER_ROWS=0
_PICKER_ALT_SCREEN=false
_PICKER_STTY=''

terminal_cols() {
  local cols

  cols=''
  if command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
  cols="${cols:-${COLUMNS:-80}}"
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  ((cols < 32)) && cols=32
  printf '%s' "$cols"
}

terminal_lines() {
  local lines

  lines=''
  if command -v tput >/dev/null 2>&1; then
    lines="$(tput lines 2>/dev/null || true)"
  fi
  lines="${lines:-${LINES:-24}}"
  [[ "$lines" =~ ^[0-9]+$ ]] || lines=24
  ((lines < 8)) && lines=8
  printf '%s' "$lines"
}

picker_save_cursor() {
  if command -v tput >/dev/null 2>&1 && tput sc 2>/dev/null; then
    return
  fi
  printf '\0337'
}

picker_restore_cursor() {
  if command -v tput >/dev/null 2>&1 && tput rc 2>/dev/null; then
    return
  fi
  printf '\0338'
}

picker_hide_cursor() {
  if command -v tput >/dev/null 2>&1 && tput civis 2>/dev/null; then
    return
  fi
  printf '\033[?25l'
}

picker_show_cursor() {
  if command -v tput >/dev/null 2>&1 && tput cnorm 2>/dev/null; then
    return
  fi
  printf '\033[?25h'
}

picker_enable_input() {
  local state

  if ! command -v stty >/dev/null 2>&1 || ! state="$(stty -g 2>/dev/null)"; then
    return
  fi
  if stty -echo -icanon min 1 time 0 2>/dev/null; then
    _PICKER_STTY="$state"
  fi
}

picker_restore_input() {
  if [[ -z "$_PICKER_STTY" ]]; then
    return
  fi
  if ! stty "$_PICKER_STTY" 2>/dev/null; then
    printf 'Failed to restore terminal input mode.\n' >&2
  fi
  _PICKER_STTY=''
}

picker_cleanup() {
  picker_restore_input
  picker_show_cursor
  picker_exit_screen
}

picker_abort() {
  exit 130
}

picker_quit() {
  exit 131
}

picker_suspend() {
  local mode="$_PICKER_MODE" cur="$_PICKER_CUR"

  picker_cleanup
  trap - TSTP
  kill -STOP "$$"

  picker_enter_screen
  picker_save_cursor
  picker_hide_cursor
  picker_enable_input
  picker_render_prompt
  picker_render_full "$mode" "$cur"
  trap 'picker_suspend' TSTP
}

picker_enter_screen() {
  _PICKER_ALT_SCREEN=true

  if command -v tput >/dev/null 2>&1 && tput smcup 2>/dev/null; then
    :
  else
    printf '\033[?1049h'
  fi

  if command -v tput >/dev/null 2>&1 && tput clear 2>/dev/null; then
    return
  fi
  printf '\033[2J\033[H'
}

picker_exit_screen() {
  if [[ "$_PICKER_ALT_SCREEN" != true ]]; then
    return
  fi

  if command -v tput >/dev/null 2>&1 && tput rmcup 2>/dev/null; then
    :
  else
    printf '\033[?1049l'
  fi
  _PICKER_ALT_SCREEN=false
}

picker_render_prompt() {
  local cols

  cols="$(terminal_cols)"
  if ((cols >= 86)); then
    printf '%s\n' "  ${BOLD}◆${RESET}  ${BOLD}Which configs do you want to manage?${RESET}"
    printf '%s\n' "     ${DIM}↑/↓ or j/k navigate · space toggle · a all/none · m mode · enter confirm · q quit${RESET}"
  elif ((cols >= 59)); then
    printf '%s\n' "  ${BOLD}◆${RESET}  ${BOLD}Which configs do you want to manage?${RESET}"
    printf '%s\n' "  ${DIM}j/k move · space toggle · a all · m mode · enter · q quit${RESET}"
  else
    printf '%s\n' "  ${BOLD}◆${RESET}  ${BOLD}Manage configs${RESET}"
    printf '%s\n' "  ${DIM}j/k space a m enter q${RESET}"
  fi
  printf '\n'
}

truncate_text() {
  local text="$1" max="$2"
  local head_len tail_len

  if ((max <= 0)); then
    return
  fi
  if ((${#text} <= max)); then
    printf '%s' "$text"
    return
  fi
  if ((max < 5)); then
    printf '%s' "${text:0:max}"
    return
  fi

  head_len=$(( (max - 3 + 1) / 2 ))
  tail_len=$(( max - 3 - head_len ))
  printf '%s...%s' "${text:0:head_len}" "${text: -tail_len}"
}

compact_path() {
  local path="$1"

  if [[ "$path" == "$HOME" ]]; then
    printf '~'
  elif [[ "$path" == "$HOME/"* ]]; then
    printf '~%s' "${path:${#HOME}}"
  else
    printf '%s' "$path"
  fi
}

picker_status_label() {
  case "$1" in
    linked) printf 'linked' ;;
    missing) printf 'missing' ;;
    foreign) printf 'foreign' ;;
    blocked) printf 'blocked' ;;
  esac
}

picker_render_row() {
  local index="$1" current="$2" selected="$3" cols="$4"
  local entry="${_PICKER_ENTRIES[$index]}"
  local src="${entry%%|*}" target="${entry##*|}"
  local source="$DOTVERSE/$src"
  local name="${src%%/*}" state status status_color
  local target_display max_target

  name="$(truncate_text "$name" 10)"
  state="$(link_state "$source" "$target")"
  status="$(picker_status_label "$state")"
  target_display="$(compact_path "$target")"
  max_target=$((cols - 30 - ${#status}))
  ((max_target < 1)) && max_target=1
  target_display="$(truncate_text "$target_display" "$max_target")"

  status_color="$DIM"
  case "$state" in
    linked) status_color="$GREEN" ;;
    foreign|blocked) status_color="$YELLOW" ;;
  esac

  if ((current)); then
    if ((selected)); then
      printf '  %s❯%s %s%s%s  %s%-10s%s  %s  %s[%s]%s\033[K' \
        "$CYAN" "$RESET" "$GREEN" '◆' "$RESET" "$BOLD" "$name" "$RESET" \
        "$target_display" "$status_color" "$status" "$RESET"
    else
      printf '  %s❯%s %s%s%s  %s%-10s%s  %s  %s[%s]%s\033[K' \
        "$CYAN" "$RESET" "$DIM" '◇' "$RESET" "$BOLD" "$name" "$RESET" \
        "$target_display" "$status_color" "$status" "$RESET"
    fi
  elif ((selected)); then
    printf '    %s%s%s  %-10s  %s  %s[%s]%s\033[K' \
      "$GREEN" '◆' "$RESET" "$name" "$target_display" \
      "$status_color" "$status" "$RESET"
  else
    printf '    %s%s%s  %-10s  %s  %s[%s]%s\033[K' \
      "$DIM" '◇' "$RESET" "$name" "$target_display" \
      "$status_color" "$status" "$RESET"
  fi
}

picker_calculate_view_start() {
  local cur="$1" count="$2" max_rows="$3" view_start=0

  if ((count > max_rows)); then
    view_start=$((cur - max_rows / 2))
    ((view_start < 0)) && view_start=0
    ((view_start > count - max_rows)) && view_start=$((count - max_rows))
  fi
  printf '%s' "$view_start"
}

picker_selected_count() {
  local count=0 i

  for i in "${!_PICKER_SELECTION[@]}"; do
    (( _PICKER_SELECTION[$i] == 1 )) && count=$((count + 1))
  done
  printf '%s' "$count"
}

picker_render_frame_line() {
  local row="$1" mode="$2" cur="$3" cols="$4"
  local mode_label mode_color selected_count index

  case "$row" in
    0)
      if [[ "$mode" == unlink ]]; then
        mode_label='Unlink managed symlinks'
        mode_color="$YELLOW"
      else
        mode_label='Install symlinks'
        mode_color="$GREEN"
      fi
      if ((cols < 50)); then
        printf '  %sMode: %s%s%s  %s[m]%s' \
          "$BOLD" "$mode_color" "${mode_label%% *}" "$RESET" "$DIM" "$RESET"
      else
        printf '  %sMode: %s%s%s  %s[m] switch mode%s' \
          "$BOLD" "$mode_color" "$mode_label" "$RESET" "$DIM" "$RESET"
      fi
      ;;
    1)
      selected_count="$(picker_selected_count)"
      printf '  %sSelected: %d/%d%s' \
        "$DIM" "$selected_count" "${#_PICKER_ENTRIES[@]}" "$RESET"
      ;;
    2)
      if (( _PICKER_VIEW_START > 0 )); then
        printf '  %s... more above ...%s' "$DIM" "$RESET"
      fi
      ;;
    *)
      if ((row >= 3 && row < 3 + _PICKER_MAX_ROWS)); then
        index=$((_PICKER_VIEW_START + row - 3))
        if ((index < _PICKER_VIEW_END)); then
          picker_render_row "$index" "$((index == cur))" "${_PICKER_SELECTION[$index]}" "$cols"
        fi
      elif ((row == 3 + _PICKER_MAX_ROWS)) && (( _PICKER_VIEW_END < ${#_PICKER_ENTRIES[@]} )); then
        printf '  %s... more below ...%s' "$DIM" "$RESET"
      fi
      ;;
  esac
}

picker_move_to_row() {
  local row="$1"

  picker_restore_cursor
  if ((row > 0)); then
    printf '\033[%dB' "$row"
  fi
  printf '\r'
}

picker_clear_row() {
  printf '\033[2K\r'
}

picker_render_full() {
  local mode="$1" cur="$2"
  local cols lines max_rows view_start view_end new_rows rows_to_clear row

  cols="$(terminal_cols)"
  lines="$(terminal_lines)"
  max_rows=$((lines - 8))
  ((max_rows < 1)) && max_rows=1
  view_start="$(picker_calculate_view_start "$cur" "${#_PICKER_ENTRIES[@]}" "$max_rows")"
  view_end=$((view_start + max_rows))
  ((view_end > ${#_PICKER_ENTRIES[@]})) && view_end=${#_PICKER_ENTRIES[@]}
  new_rows=$((max_rows + 4))
  rows_to_clear=$new_rows
  ((rows_to_clear < _PICKER_RENDER_ROWS)) && rows_to_clear=$_PICKER_RENDER_ROWS

  _PICKER_MODE="$mode"
  _PICKER_CUR="$cur"
  _PICKER_VIEW_START="$view_start"
  _PICKER_VIEW_END="$view_end"
  _PICKER_MAX_ROWS="$max_rows"
  _PICKER_COLS="$cols"
  _PICKER_LINES="$lines"
  _PICKER_RENDER_ROWS="$new_rows"

  for ((row = 0; row < rows_to_clear; row++)); do
    picker_move_to_row "$row"
    picker_clear_row
    if ((row < new_rows)); then
      picker_render_frame_line "$row" "$mode" "$cur" "$cols"
    fi
  done
}

picker_update_row() {
  local index="$1" row

  if ((index < _PICKER_VIEW_START || index >= _PICKER_VIEW_END)); then
    return
  fi
  row=$((3 + index - _PICKER_VIEW_START))
  picker_move_to_row "$row"
  picker_clear_row
  picker_render_row "$index" "$((index == _PICKER_CUR))" \
    "${_PICKER_SELECTION[$index]}" "$_PICKER_COLS"
}

picker_update_header() {
  local row="$1"

  picker_move_to_row "$row"
  picker_clear_row
  picker_render_frame_line "$row" "$_PICKER_MODE" "$_PICKER_CUR" "$_PICKER_COLS"
}

picker_update_visible_rows() {
  local index

  for ((index = _PICKER_VIEW_START; index < _PICKER_VIEW_END; index++)); do
    picker_update_row "$index"
  done
}

picker_clear_rendered_rows() {
  local row

  for ((row = 0; row < _PICKER_RENDER_ROWS; row++)); do
    picker_move_to_row "$row"
    picker_clear_row
  done
  picker_restore_cursor
}

picker_refresh() {
  local mode="$1" cur="$2" old_cur="$3" action="$4"
  local cols lines max_rows view_start
  local layout_changed=false

  cols="$(terminal_cols)"
  lines="$(terminal_lines)"
  max_rows=$((lines - 8))
  ((max_rows < 1)) && max_rows=1
  view_start="$(picker_calculate_view_start "$cur" "${#_PICKER_ENTRIES[@]}" "$max_rows")"

  if [[ "$action" == mode || "$cols" != "$_PICKER_COLS" || "$lines" != "$_PICKER_LINES" ||
    "$view_start" != "$_PICKER_VIEW_START" ]]; then
    layout_changed=true
  fi

  if [[ "$layout_changed" == true ]]; then
    picker_render_full "$mode" "$cur"
    return
  fi

  _PICKER_MODE="$mode"
  _PICKER_CUR="$cur"
  case "$action" in
    move)
      if ((old_cur != cur)); then
        picker_update_row "$old_cur"
        picker_update_row "$cur"
      fi
      ;;
    toggle)
      picker_update_header 1
      picker_update_row "$cur"
      ;;
    all)
      picker_update_header 1
      picker_update_visible_rows
      ;;
  esac
}

pick_symlinks() {
  local -a entries=("$@")
  local n=${#entries[@]} mode="$MODE"
  local cur=0 old_cur key rest i state action
  local cancelled=false
  _SELECTED=()
  _PICKER_CANCELLED=false
  _PICKER_ENTRIES=("${entries[@]}")
  _PICKER_SELECTION=()

  if [[ "$YES" == true || ! -t 0 || ! -t 1 || "${TERM:-}" == dumb ]]; then
    _SELECTED=("${entries[@]}")
    return
  fi

  for i in "${!entries[@]}"; do
    if [[ "$mode" == unlink ]]; then
      state="$(link_state "$DOTVERSE/${entries[$i]%%|*}" "${entries[$i]##*|}")"
      [[ "$state" == linked ]] && _PICKER_SELECTION[i]=1 || _PICKER_SELECTION[i]=0
    else
      _PICKER_SELECTION[i]=1
    fi
  done

  trap 'picker_cleanup' EXIT
  trap 'picker_abort' INT TERM
  trap 'picker_quit' QUIT
  trap 'picker_suspend' TSTP
  picker_enable_input
  picker_enter_screen
  picker_save_cursor
  picker_hide_cursor
  picker_render_prompt
  picker_render_full "$mode" "$cur"

  while true; do
    if [[ -n "$_PICKER_STTY" ]]; then
      IFS= read -rn1 key || { cancelled=true; break; }
    else
      IFS= read -rsn1 key || { cancelled=true; break; }
    fi
    old_cur=$cur
    action=none

    case "$key" in
      $'\x1b')
        if [[ -n "$_PICKER_STTY" ]]; then
          IFS= read -rn2 -t 0.05 rest || rest=''
        else
          IFS= read -rsn2 -t 0.05 rest || rest=''
        fi
        case "$rest" in
          '[A')
            [[ $cur -gt 0 ]] && cur=$((cur - 1)) || true
            action=move
            ;;
          '[B')
            [[ $cur -lt $((n-1)) ]] && cur=$((cur + 1)) || true
            action=move
            ;;
        esac
        ;;
      'k')
        [[ $cur -gt 0 ]] && cur=$((cur - 1)) || true
        action=move
        ;;
      'j')
        [[ $cur -lt $((n-1)) ]] && cur=$((cur + 1)) || true
        action=move
        ;;
      ' ')
        _PICKER_SELECTION[cur]=$((1 - _PICKER_SELECTION[cur]))
        action=toggle
        ;;
      'a'|'A')
        local any_off=0
        for v in "${_PICKER_SELECTION[@]}"; do
          if [[ $v -eq 0 ]]; then any_off=1; break; fi
        done
        local nv=$(( any_off ? 1 : 0 ))
        for i in "${!_PICKER_SELECTION[@]}"; do _PICKER_SELECTION[i]=$nv; done
        action=all
        ;;
      'm'|'M')
        if [[ "$mode" == unlink ]]; then
          mode=install
          for i in "${!_PICKER_SELECTION[@]}"; do _PICKER_SELECTION[i]=1; done
        else
          mode=unlink
          for i in "${!_PICKER_SELECTION[@]}"; do
            state="$(link_state "$DOTVERSE/${entries[$i]%%|*}" "${entries[$i]##*|}")"
            [[ "$state" == linked ]] && _PICKER_SELECTION[i]=1 || _PICKER_SELECTION[i]=0
          done
        fi
        action=mode
        ;;
      ''|$'\n') break ;;
      'q'|$'\x03')
        cancelled=true
        break
        ;;
    esac
    picker_refresh "$mode" "$cur" "$old_cur" "$action"
  done

  MODE="$mode"
  picker_clear_rendered_rows
  picker_restore_input
  picker_show_cursor
  picker_exit_screen
  trap - EXIT INT TERM QUIT TSTP
  printf '\n'

  if [[ "$cancelled" == true ]]; then
    _PICKER_CANCELLED=true
    printf '  Cancelled.\n\n'
    return
  fi

  for i in "${!entries[@]}"; do
    if [[ ${_PICKER_SELECTION[$i]} -eq 1 ]]; then _SELECTED+=("${entries[$i]}"); fi
  done
}

perform_selected_action() {
  local mode="$1" entry source target name

  for entry in "${_SELECTED[@]}"; do
    source="$DOTVERSE/${entry%%|*}"
    target="${entry##*|}"
    name="${entry%%|*}"
    name="${name##*/}"
    if [[ "$mode" == unlink ]]; then
      unlink_config "$source" "$target" "$name"
    else
      link_config "$source" "$target"
    fi
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
if ((${#DEPRECATED_SYMLINKS[@]})); then
  for entry in "${DEPRECATED_SYMLINKS[@]}"; do
    cleanup_deprecated "${entry%%|*}" "${entry##*|}"
  done
fi

# Build list for current platform
all_entries=("${SYMLINKS[@]}")
case "$(uname -s)" in
  Darwin|Linux) all_entries+=("${DARWIN_SYMLINKS[@]}") ;;
  *) printf '  Skipping platform symlinks: unsupported platform (%s)\n\n' "$(uname -s)" >&2 ;;
esac

pick_symlinks "${all_entries[@]}"

if [[ "$_PICKER_CANCELLED" == true ]]; then
  exit 0
fi

if [[ ${#_SELECTED[@]} -eq 0 ]]; then
  printf '%s\n\n' "  ${DIM}Nothing selected.${RESET}"
  exit 0
fi

if [[ "$MODE" == unlink ]]; then
  printf '%s\n\n' "  ${BOLD}Removing managed symlinks${RESET}"
  perform_selected_action unlink
  printf '\n'
  printf '%s\n\n' "  ${GREEN}◆${RESET}  ${BOLD}Unlink complete!${RESET}"
else
  printf '%s\n\n' "  ${BOLD}Creating symlinks${RESET}"
  perform_selected_action install

  printf '\n'
  printf '%s\n\n' "  ${BOLD}Zsh dependencies${RESET}"
  setup_zsh_dependencies

  printf '\n'
  printf '%s\n\n' "  ${GREEN}◆${RESET}  ${BOLD}All done!${RESET}"
fi

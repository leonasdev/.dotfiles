#!/bin/bash
# Claude Code tmux integration
#
# Usage: claude.sh <command> [args...]
#   select <window_id> <current_path> - Show directory picker if multiple unique pane paths, else popup directly
#   popup <window_id> <work_dir>      - Toggle Claude popup for a window
#   cleanup                           - Clean up orphaned claude sessions
#   bell <session_name>               - Handle bell from claude (notify main window)
#   clear-bell <window_id>            - Clear bell indicator (called internally by popup)


SOCKET="claude"
MAIN_SOCKET="default"
BELL_COLOR="#d97757"
BORDER_COLOR="#d97757"
PREFIX="win"
SELF="$HOME/.config/tmux/claude.sh"

cmd_select() {
  local win_id="${1//@/}"
  local current_path="$2"
  local session="${PREFIX}${win_id}"

  # Only show menu when creating a new session
  if tmux -L "$SOCKET" has-session -t "$session" 2>/dev/null; then
    cmd_popup "$win_id" "$current_path"
    return
  fi

  # Get unique paths from all panes in this window
  local paths
  paths=$(tmux list-panes -t "@${win_id}" -F "#{pane_current_path}" | sort -u)
  local count
  count=$(echo "$paths" | wc -l)

  if [ "$count" -le 1 ]; then
    cmd_popup "$win_id" "$current_path"
    return
  fi

  # Build display-menu arguments
  local menu_args=()
  local idx=1
  while IFS= read -r path; do
    local label="${path/#$HOME/\~}"
    if [ "$path" = "$current_path" ]; then
      label="$label (current)"
    fi
    local key=""
    if [ "$idx" -le 9 ]; then
      key="$idx"
    fi
    menu_args+=("$label" "$key" "run-shell '$SELF popup $win_id \"$path\"'")
    ((idx++))
  done <<< "$paths"
  menu_args+=("" "" "")
  menu_args+=("Cancel" "Escape" "")

  tmux display-menu -T " Claude: select working directory " -b heavy -S "fg=${BORDER_COLOR}" -H "bg=${BORDER_COLOR},fg=default" "${menu_args[@]}"
}

cmd_popup() {
  local win_id="${1//@/}"
  local session="${PREFIX}${win_id}"
  local work_dir="$2"

  if [[ "$TMUX" == */${SOCKET},* ]]; then
    tmux detach-client
    return
  fi

  cmd_clear_bell "@${win_id}"

  if ! tmux -L "$SOCKET" has-session -t "$session" 2>/dev/null; then
    tmux -L "$SOCKET" new-session -d -s "$session" -c "$work_dir"
    tmux -L "$SOCKET" set-option -g status-left ""
    tmux -L "$SOCKET" set-option -g status-right ""
    tmux -L "$SOCKET" set-hook -g alert-bell \
      "run-shell '$SELF bell #{session_name}'"
    tmux -L "$SOCKET" send-keys -t "$session" " clear && claude" Enter
  fi

  tmux display-popup -E -w 90% -h 90% -S "fg=${BORDER_COLOR}" -b heavy \
    "tmux -L $SOCKET attach-session -t $session"
}

cmd_cleanup() {
  tmux -L "$SOCKET" list-sessions &>/dev/null || return 0

  for session in $(tmux -L "$SOCKET" list-sessions -F "#{session_name}" 2>/dev/null); do
    local win_id="${session#${PREFIX}}"
    if ! tmux -L "$MAIN_SOCKET" list-windows -a -F "#{window_id}" 2>/dev/null \
         | grep -q "^@${win_id}$"; then
      tmux -L "$SOCKET" kill-session -t "$session" 2>/dev/null
    fi
  done
}

cmd_bell() {
  local session="$1"
  local win_id="@${session#${PREFIX}}"

  local tty
  tty=$(tmux -L "$MAIN_SOCKET" display-message -t "$win_id" -p "#{pane_tty}")
  printf "\a" > "$tty"

  local attached
  attached=$(tmux -L "$SOCKET" display-message -t "$session" -p "#{session_attached}" 2>/dev/null || echo "0")

  if [ "$attached" = "0" ]; then
    local orig
    orig=$(tmux -L "$MAIN_SOCKET" display-message -t "$win_id" -p "#{window_name}")

    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" @claude_bell 1
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" @claude_orig_name "$orig"
    tmux -L "$MAIN_SOCKET" rename-window -t "$win_id" "#[fg=${BELL_COLOR}]✦ #[default]$orig"
  fi
}

cmd_clear_bell() {
  local win_id="$1"

  if [ "$(tmux -L "$MAIN_SOCKET" show-option -w -t "$win_id" -qv @claude_bell)" = "1" ]; then
    local orig
    orig=$(tmux -L "$MAIN_SOCKET" show-option -w -t "$win_id" -qv @claude_orig_name)
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" -u @claude_bell
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" -u @claude_orig_name
    tmux -L "$MAIN_SOCKET" rename-window -t "$win_id" "$orig"
  fi
}

case "${1:-}" in
  select)    cmd_select "$2" "$3" ;;
  popup)     cmd_popup "$2" "$3" ;;
  cleanup)   cmd_cleanup ;;
  bell)      cmd_bell "$2" ;;
  clear-bell) cmd_clear_bell "$2" ;;
  *)         echo "Usage: $0 {select|popup|cleanup|bell|clear-bell}" >&2; exit 1 ;;
esac

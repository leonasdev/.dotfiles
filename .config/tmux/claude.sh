#!/bin/bash
# Claude Code tmux integration
#
# Usage: claude.sh <command> [args...]
#   select <window_id> <current_path> - Show session picker (orphans + new) or popup directly
#   popup <window_id> <work_dir>      - Toggle Claude popup for a window
#   adopt <window_id> <session_name>  - Re-key an orphan session to the current window
#   cleanup                           - Kill orphan claude sessions (manual; no longer auto-triggered)
#   bell <session_name>               - Handle bell from claude (notify main window)
#   clear-bell <window_id>            - Clear bell indicator (called internally by popup)
#   kill-window <window_id>           - Confirm kill-window (session persists as orphan)


SOCKET="claude"
MAIN_SOCKET="default"
BELL_COLOR="#d97757"
BORDER_COLOR="#d97757"
PREFIX="win"
SELF="$HOME/.config/tmux/claude.sh"

format_relative_time() {
  local ts="$1"
  [ -z "$ts" ] && { echo "?"; return; }
  local now diff
  now=$(date +%s)
  diff=$((now - ts))
  if [ "$diff" -lt 0 ]; then
    echo "just now"
  elif [ "$diff" -lt 60 ]; then
    echo "${diff}s ago"
  elif [ "$diff" -lt 3600 ]; then
    echo "$((diff / 60))m ago"
  elif [ "$diff" -lt 86400 ]; then
    echo "$((diff / 3600))h ago"
  else
    echo "$((diff / 86400))d ago"
  fi
}

cmd_select() {
  local win_id="${1//@/}"
  local current_path="$2"
  local session="${PREFIX}${win_id}"

  # Inside the popup itself → toggle hide (detach). The claude socket inherits
  # this same tmux.conf, so prefix+space inside the popup would otherwise
  # re-enter cmd_select with the popup's internal window id and mis-fire.
  if [[ "$TMUX" == */${SOCKET},* ]]; then
    tmux detach-client
    return
  fi

  # Existing session for this window — just toggle popup
  if tmux -L "$SOCKET" has-session -t "$session" 2>/dev/null; then
    cmd_popup "$win_id" "$current_path"
    return
  fi

  # Gather orphan sessions (claude sessions with no matching main-socket window)
  local orphans=()
  if tmux -L "$SOCKET" list-sessions &>/dev/null; then
    local live_windows
    live_windows=$(tmux -L "$MAIN_SOCKET" list-windows -a -F "#{window_id}" 2>/dev/null)
    while IFS=$'\t' read -r sname spath sactivity orig_name; do
      [ -z "$sname" ] && continue
      local oid="${sname#${PREFIX}}"
      if echo "$live_windows" | grep -q "^@${oid}$"; then
        continue
      fi
      orphans+=("$sname"$'\t'"$spath"$'\t'"$sactivity"$'\t'"$orig_name")
    done < <(tmux -L "$SOCKET" list-sessions -F '#{session_name}	#{session_path}	#{session_activity}	#{@orig_window_name}' 2>/dev/null)
  fi

  # Unique pane paths in current window
  local paths
  paths=$(tmux list-panes -t "@${win_id}" -F "#{pane_current_path}" | sort -u)
  local path_count
  path_count=$(echo "$paths" | wc -l)

  # Fast path: no orphans, single pane path → popup directly
  if [ ${#orphans[@]} -eq 0 ] && [ "$path_count" -le 1 ]; then
    cmd_popup "$win_id" "$current_path"
    return
  fi

  local menu_args=()
  local idx=1

  # Orphan entries first (most recent activity at top)
  if [ ${#orphans[@]} -gt 0 ]; then
    local sorted_orphans
    sorted_orphans=$(printf '%s\n' "${orphans[@]}" | sort -t$'\t' -k3,3nr)
    while IFS=$'\t' read -r sname spath sactivity orig_name; do
      local short_path="${spath/#$HOME/\~}"
      local label
      if [ -n "$orig_name" ]; then
        label="· ${orig_name}: ${short_path}"
      else
        label="· ${short_path}"
      fi
      label="${label} ($(format_relative_time "$sactivity"))"
      local key=""
      if [ "$idx" -le 9 ]; then key="$idx"; fi
      menu_args+=("$label" "$key" "run-shell '$SELF adopt $win_id $sname'")
      ((idx++))
    done <<< "$sorted_orphans"
    menu_args+=("" "" "")
  fi

  # New-session entries
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    local label="${path/#$HOME/\~}"
    if [ "$path" = "$current_path" ]; then
      label="${label} (current)"
    fi
    label="+ ${label}"
    local key=""
    if [ "$idx" -le 9 ]; then key="$idx"; fi
    menu_args+=("$label" "$key" "run-shell '$SELF popup $win_id \"$path\"'")
    ((idx++))
  done <<< "$paths"

  menu_args+=("" "" "")
  menu_args+=("Cancel" "Escape" "")

  tmux display-menu -T " Claude: select session " -b heavy -S "fg=${BORDER_COLOR}" -H "bg=${BORDER_COLOR},fg=default" "${menu_args[@]}"
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
    local orig_name
    orig_name=$(tmux -L "$MAIN_SOCKET" display-message -t "@${win_id}" -p "#{window_name}" 2>/dev/null || echo "")

    tmux -L "$SOCKET" new-session -d -s "$session" -c "$work_dir"
    tmux -L "$SOCKET" set-option -g status-left ""
    tmux -L "$SOCKET" set-option -g status-right ""
    tmux -L "$SOCKET" set-option -g monitor-bell on
    tmux -L "$SOCKET" set-option -g bell-action any
    tmux -L "$SOCKET" set-hook -g alert-bell \
      "run-shell '$SELF bell #{session_name}'"
    tmux -L "$SOCKET" set-option -t "$session" @orig_window_name "$orig_name"
    tmux -L "$SOCKET" send-keys -t "$session" " clear && claude" Enter
  fi

  tmux display-popup -E -w 96% -h 90% -S "fg=${BORDER_COLOR}" -b heavy -T " Claude Code " \
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

  # Send bell directly to terminal clients, bypassing tmux's bell-action
  while IFS= read -r clt; do
    printf "\a" > "$clt"
  done < <(tmux -L "$MAIN_SOCKET" list-clients -F "#{client_tty}")

  local attached
  attached=$(tmux -L "$SOCKET" display-message -t "$session" -p "#{session_attached}" 2>/dev/null || echo "0")

  if [ "$attached" = "0" ]; then
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" @claude_bell 1
  fi
}

cmd_clear_bell() {
  local win_id="$1"
  tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" -uq @claude_bell
}

cmd_kill_window() {
  local win_id="${1//@/}"
  local session="${PREFIX}${win_id}"
  local win_name
  win_name=$(tmux display-message -t "@${win_id}" -p "#{window_name}")

  if tmux -L "$SOCKET" has-session -t "$session" 2>/dev/null; then
    tmux display-menu \
      -T " Claude session in '${win_name}' will be kept as orphan " \
      -b heavy -S "fg=${BORDER_COLOR}" -H "bg=${BORDER_COLOR},fg=default" \
      "Kill window (session persists)" "y" "kill-window -t @${win_id}" \
      "" "" "" \
      "Cancel" "Escape" ""
  else
    tmux confirm-before -p "Kill window '${win_name}'? (y/n) " "kill-window -t @${win_id}"
  fi
}

cmd_adopt() {
  local win_id="${1//@/}"
  local orphan_session="$2"
  local target_session="${PREFIX}${win_id}"

  if ! tmux -L "$SOCKET" has-session -t "$orphan_session" 2>/dev/null; then
    return 1
  fi

  tmux -L "$SOCKET" rename-session -t "$orphan_session" "$target_session"

  local current_name
  current_name=$(tmux -L "$MAIN_SOCKET" display-message -t "@${win_id}" -p "#{window_name}" 2>/dev/null || echo "")
  tmux -L "$SOCKET" set-option -t "$target_session" @orig_window_name "$current_name"

  cmd_popup "$win_id" ""
}

case "${1:-}" in
  select)      cmd_select "$2" "$3" ;;
  popup)       cmd_popup "$2" "$3" ;;
  adopt)       cmd_adopt "$2" "$3" ;;
  cleanup)     cmd_cleanup ;;
  bell)        cmd_bell "$2" ;;
  clear-bell)  cmd_clear_bell "$2" ;;
  kill-window) cmd_kill_window "$2" ;;
  *)           echo "Usage: $0 {select|popup|adopt|cleanup|bell|clear-bell|kill-window}" >&2; exit 1 ;;
esac

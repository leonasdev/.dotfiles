#!/bin/bash
# Claude Code tmux integration
#
# Usage: claude.sh <command> [args...]
#   select <window_id> <current_path> - Show session picker (orphans + new) or popup directly
#   popup <window_id> <work_dir>      - Toggle Claude popup for a window
#   adopt <window_id> <session_name>  - Re-key an orphan session to the current window
#   cleanup                           - Kill orphan claude sessions (manual; no longer auto-triggered)
#   bell <session_name>               - Handle bell from claude (notify main window)
#   sync <session_name>               - Recompute bell indicator from unread bell flags (tmux hooks)
#   kill-window <window_id>           - Confirm kill-window (session persists as orphan)
#   restart-all                       - Menu: restart stale claude processes to apply an update
#   restart-run                       - Do the restart (called from the restart-all menu)
#   restart-one <pid>                 - Restart a single session by pid (run by hand)
#   sidebar-add <window_id>           - Add the agent sidebar pane to a popup window (hook)
#   sidebar-check <window_id>         - Close the window if only sidebar panes remain (hook)
#   sidebar-add-all                   - Add it to every popup window that lacks one
#   sidebar-remove-all                - Remove every sidebar pane


SOCKET="claude"
MAIN_SOCKET="default"
SIDEBAR="$HOME/.config/tmux/agent-sidebar.sh"
# Popup / menu border colour comes from the theme (@t_brand_claude, see
# tmux.conf Theme section); the literal is only a fallback if the token is
# missing on the main server.
BORDER_COLOR=$(tmux -L "default" show -gv @t_brand_claude 2>/dev/null)
BORDER_COLOR="${BORDER_COLOR:-#d97757}"
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

# Display name for an orphan session: "<original window name>: <path>"
orphan_label() {
  local spath="$1" orig_name="$2"
  local short_path="${spath/#$HOME/\~}"
  if [ -n "$orig_name" ]; then
    echo "${orig_name}: ${short_path}"
  else
    echo "$short_path"
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

  # No fast path: creating a session always requires an explicit confirmation,
  # so that a stray prefix+space on a window without a session can't silently
  # spawn (and make you wait on) a new claude process.

  local menu_args=()
  local idx=1

  # Group headers only make sense when there are two groups to tell apart.
  # A leading "-" marks a menu entry disabled, so it renders dim and is skipped
  # when moving the selection.
  local grouped=0
  [ ${#orphans[@]} -gt 0 ] && grouped=1

  # Orphan entries first (most recent activity at top)
  if [ "$grouped" -eq 1 ]; then
    local sorted_orphans
    sorted_orphans=$(printf '%s\n' "${orphans[@]}" | sort -t$'\t' -k3,3nr)

    # Pad the name column so the relative times line up
    local name_width=0 name
    while IFS=$'\t' read -r sname spath sactivity orig_name; do
      name=$(orphan_label "$spath" "$orig_name")
      [ ${#name} -gt "$name_width" ] && name_width=${#name}
    done <<< "$sorted_orphans"

    menu_args+=("-↻ Resume a previous session" "" "")
    while IFS=$'\t' read -r sname spath sactivity orig_name; do
      local label
      label=$(printf '  %-*s   %s' "$name_width" \
        "$(orphan_label "$spath" "$orig_name")" \
        "$(format_relative_time "$sactivity")")
      local key=""
      if [ "$idx" -le 9 ]; then key="$idx"; fi
      menu_args+=("$label" "$key" "run-shell '$SELF adopt $win_id $sname'")
      ((idx++))
    done <<< "$sorted_orphans"

    menu_args+=("" "" "")
    menu_args+=("-+ Start a new session" "" "")
  fi

  # New-session entries. Under a header they are indented; standing alone they
  # carry the "+" themselves.
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    local label="${path/#$HOME/\~}"
    if [ "$path" = "$current_path" ]; then
      label="${label}  (this pane)"
    fi
    if [ "$grouped" -eq 1 ]; then
      label="  ${label}"
    else
      label="+ ${label}"
    fi
    local key=""
    if [ "$idx" -le 9 ]; then key="$idx"; fi
    menu_args+=("$label" "$key" "run-shell '$SELF popup $win_id \"$path\"'")
    ((idx++))
  done <<< "$paths"

  menu_args+=("" "" "")
  menu_args+=("Cancel" "Escape" "")

  local title=" Claude Code "
  if [ "$grouped" -eq 0 ]; then
    title=" Claude Code: no session in this window "
  fi

  # "--" is required: the header entries start with "-" and would otherwise be
  # parsed as flags.
  #
  # "|| true": display-menu blocks until the menu is dismissed, so a client that
  # dies while it is open (ssh drop) takes the menu with it and the exit status
  # comes back as 128+signal. Without this, run-shell reports "returned 129" and
  # parks the pane in view-mode, waiting for a "q" you only see on reattach.
  tmux display-menu -T "$title" -b heavy -S "fg=${BORDER_COLOR}" -H "bg=${BORDER_COLOR},fg=default" -- "${menu_args[@]}" || true
}

# Server-wide options for the claude socket. Re-applied on every popup rather
# than once at session creation: that server reads this same tmux.conf, so a
# prefix+r sourced from inside the popup puts the main status-left/right back
# and flips monitor-bell off again -- which silently kills the bell indicator,
# since the alert-bell hook survives but never fires. Setting them here means
# the next popup heals it.
claude_server_options() {
  # status-left/right for the popup live in tmux.conf's claude-socket block.
  tmux -L "$SOCKET" set-option -g monitor-bell on
  tmux -L "$SOCKET" set-option -g bell-action any
  tmux -L "$SOCKET" set-hook -g alert-bell "run-shell '$SELF bell #{session_name}'"
  # Viewing a window clears its bell flag (tmux does this in session_set_current
  # and on attach, before it fires these hooks), so the indicator is recomputed
  # whenever the visible window changes.
  tmux -L "$SOCKET" set-hook -g session-window-changed "run-shell '$SELF sync #{session_name}'"
  tmux -L "$SOCKET" set-hook -g client-session-changed "run-shell '$SELF sync #{session_name}'"
  # Every window in the popup gets the agent sidebar on its left, and a window
  # whose agent pane has exited (claude quit, /exit, crash) is closed rather
  # than left as a bare sidebar. window-pane-changed is the hook that fires
  # after the dead pane is gone (the focus falls onto the sidebar); it also
  # fires on ordinary focus changes, where the check is a no-op.
  tmux -L "$SOCKET" set-hook -g after-new-window "run-shell '$SELF sidebar-add #{window_id}'"
  tmux -L "$SOCKET" set-hook -g after-new-session "run-shell '$SELF sidebar-add #{window_id}'"
  tmux -L "$SOCKET" set-hook -g window-pane-changed "run-shell '$SELF sidebar-check #{window_id}'"
}

# ==============================================================================
#  Agent sidebar (agent-sidebar.sh) - one 28-column pane per popup window
# ==============================================================================
SIDEBAR_WIDTH=28

cmd_sidebar_add() {
  local win_id="$1"
  # already has one?
  [ -n "$(tmux -L "$SOCKET" list-panes -t "$win_id" -F '#{pane_id}' -f '#{==:#{@sidebar},1}' 2>/dev/null)" ] && return 0
  # split off the left of the window's first pane; -d keeps the agent pane focused
  local first
  first=$(tmux -L "$SOCKET" list-panes -t "$win_id" -F '#{pane_id}' | head -1)
  [ -n "$first" ] || return 0
  tmux -L "$SOCKET" split-window -d -hb -l "$SIDEBAR_WIDTH" -t "$first" "$SIDEBAR"
}

# Close a window that has nothing but sidebar panes left in it.
cmd_sidebar_check() {
  local win_id="$1" others
  others=$(tmux -L "$SOCKET" list-panes -t "$win_id" -F '#{pane_id}' -f '#{!=:#{@sidebar},1}' 2>/dev/null) || return 0
  [ -z "$others" ] && [ -n "$(tmux -L "$SOCKET" list-panes -t "$win_id" -F '#{pane_id}' 2>/dev/null)" ] && \
    tmux -L "$SOCKET" kill-window -t "$win_id"
  return 0
}

cmd_sidebar_add_all() {
  local w
  for w in $(tmux -L "$SOCKET" list-windows -a -F '#{window_id}' 2>/dev/null); do
    cmd_sidebar_add "$w"
  done
}

cmd_sidebar_remove_all() {
  local p
  for p in $(tmux -L "$SOCKET" list-panes -a -F '#{pane_id}' -f '#{==:#{@sidebar},1}' 2>/dev/null); do
    tmux -L "$SOCKET" kill-pane -t "$p"
  done
}

cmd_popup() {
  local win_id="${1//@/}"
  local session="${PREFIX}${win_id}"
  local work_dir="$2"

  if [[ "$TMUX" == */${SOCKET},* ]]; then
    tmux detach-client
    return
  fi

  local created=0 orig_name
  orig_name=$(tmux -L "$MAIN_SOCKET" display-message -t "@${win_id}" -p "#{window_name}" 2>/dev/null || echo "")
  if ! tmux -L "$SOCKET" has-session -t "$session" 2>/dev/null; then
    tmux -L "$SOCKET" new-session -d -s "$session" -c "$work_dir"
    created=1
  fi

  claude_server_options
  # Refreshed on every open, not just creation: the popup's status-left shows
  # it, and the main window may have been renamed since.
  tmux -L "$SOCKET" set-option -t "$session" @orig_window_name "$orig_name"

  if [ "$created" -eq 1 ]; then
    tmux -L "$SOCKET" send-keys -t "$session" " clear && claude" Enter
    cmd_sidebar_add "$(tmux -L "$SOCKET" display -t "$session" -p '#{window_id}')"
  fi

  # "|| true": same reason as display-menu above -- the popup is torn down with
  # its client, and the signal-derived exit status would otherwise surface as a
  # bogus run-shell failure in the pane.
  # Attaching clears the current window's bell flag and fires
  # client-session-changed, which recomputes the indicator (see cmd_sync).
  tmux display-popup -E -w 100% -h 99% -S "fg=${BORDER_COLOR}" -b heavy -T " Claude Code " \
    "tmux -L $SOCKET attach-session -t $session" || true
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

  # Detached: nothing is visible, so the bell is unread regardless of flags
  # (tmux sets window_bell_flag only on non-current windows, so a bell in the
  # session's current window would otherwise leave no trace).
  # Attached: the user sees the current window; the indicator is needed only
  # if the bell landed elsewhere, which is exactly what the flags say.
  local attached
  attached=$(tmux -L "$SOCKET" display-message -t "$session" -p "#{session_attached}" 2>/dev/null || echo "0")

  if [ "$attached" = "0" ]; then
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" @claude_bell 1 2>/dev/null
    "$HOME/.config/tmux/agent-state.sh" tick
  else
    cmd_sync "$session"
  fi
}

# Indicator = "some window in this claude session still has an unread bell".
# Run from the session-window-changed / client-session-changed hooks, so it
# clears the moment the ringing window is viewed and stays while another
# window is still unread.
cmd_sync() {
  local session="$1"
  local win_id="@${session#${PREFIX}}"
  local flags
  flags=$(tmux -L "$SOCKET" list-windows -t "$session" -F "#{window_bell_flag}" 2>/dev/null) || return 0
  # sidebars first: the new window is already on screen with its sidebar's
  # cursor on the old window, so this is the latency the user can see
  "$SIDEBAR" refresh "$session"
  if grep -qx 1 <<< "$flags"; then
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" @claude_bell 1 2>/dev/null
  else
    tmux -L "$MAIN_SOCKET" set-option -w -t "$win_id" -uq @claude_bell 2>/dev/null
  fi
  # refresh the main-socket dots right away instead of waiting for the next tick
  "$HOME/.config/tmux/agent-state.sh" tick
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

# ==============================================================================
#  Restart-to-update
# ==============================================================================
#
# Claude Code writes ~/.claude/sessions/<pid>.json for every live process:
#
#   {"pid":…,"sessionId":…,"cwd":…,"version":"2.1.247","status":"idle|busy",
#    "tmux":"<session>:@<window>.%<pane>","procStart":"<stat field 22>",…}
#
# which is everything needed to restart a session in place. Two consequences
# drive the design below:
#
#   * The file is removed on clean shutdown, so it must be read before the
#     process is signalled, not after.
#   * The running version lives in the file (and in /proc/<pid>/exe), so
#     "which sessions are stale" is an exact comparison, not a guess.

SESSIONS_DIR="$HOME/.claude/sessions"
RESTART_LOG="${XDG_RUNTIME_DIR:-/tmp}/claude-tmux-restart.log"

restart_log() {
  printf '%s %s\n' "$(date +%H:%M:%S)" "$*"
}

installed_version() {
  basename "$(readlink -f "$HOME/.local/bin/claude" 2>/dev/null)"
}

# /proc/<pid>/stat field 22 is the process start time; the session file
# records it so a recycled pid can be told apart from the original. comm is
# parenthesised and may contain spaces, which shifts awk's field numbering --
# strip through ") " first, after which field 22 lands on field 20.
proc_start() {
  sed -n 's/.*) //p' "/proc/$1/stat" 2>/dev/null | awk '{print $20}'
}

# The session files are single-line JSON and every field read here is a
# string, so a sed extraction avoids a jq/python dependency.
json_str() {
  sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p' "$1"
}

# Never restart the session we are running inside: a claude that shells out to
# this script would otherwise SIGTERM its own process tree mid-command.
ancestor_pids() {
  local p="$$"
  while [ -n "$p" ] && [ "$p" != "0" ] && [ "$p" != "1" ]; do
    echo "$p"
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
}

# A monitor or a backgrounded Bash task shows up as a live child shell of the
# claude process, spawned through the Bash tool and carrying its snapshot
# signature. SIGTERM takes those with it, and the exit dialog we deliberately
# bypass ("Background work is running / The following will stop when you
# exit") is the only thing that would have offered to keep them running. A
# monitor holds its child shell for its whole lifetime rather than polling in
# bursts, so this is a steady signal, not a race.
#
# An in-flight foreground Bash call looks identical, but such a session
# reports itself busy and is held for that reason anyway.
has_shell_work() {
  pgrep -P "$1" -a 2>/dev/null | grep -q 'shell-snapshots/snapshot-'
}

# The session file records "<session>:@<window>.%<pane>" but not which tmux
# server owns it. Pane ids are per-server and can collide, so probe both
# sockets and confirm against the process's own tty.
pane_socket() {
  local pane="$1" pid="$2" pty sock
  pty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  [ -z "$pty" ] && return 1
  for sock in "$SOCKET" "$MAIN_SOCKET"; do
    if [ "$(tmux -L "$sock" display-message -t "$pane" -p '#{pane_tty}' 2>/dev/null)" = "/dev/$pty" ]; then
      echo "$sock"
      return 0
    fi
  done
  return 1
}

# A worktree session has to come back through --worktree, which is also what
# claude itself prints on exit ("Resume this session with: claude --worktree
# <name> --resume <id>"). cwd alone would land in the right directory but lose
# original_cwd/original_branch, and with them the merge-back affordance.
# --worktree reuses an existing worktree rather than erroring on it.
#
# The CLI always places worktrees at <repo>/.claude/worktrees/<name> -- the
# configurable location in settings.json is Desktop-SSH-only and documented as
# not read by the CLI. Match the *last* occurrence so a worktree entered from
# inside another worktree resolves against its immediate parent.
resume_command() {
  local cwd="$1" sid="$2" repo name
  if [[ "$cwd" == */.claude/worktrees/* ]]; then
    repo="${cwd%/.claude/worktrees/*}"
    name="${cwd##*/.claude/worktrees/}"
    name="${name%%/*}"
    printf 'cd %q && claude --worktree %q --resume %q' "$repo" "$name" "$sid"
  else
    printf 'cd %q && claude --resume %q' "$cwd" "$sid"
  fi
}

# Emits one TSV row per live session:
#   <state>\t<pid>\t<version>\t<name>\t<tmux ref>\t<sessionId>\t<cwd>
# state is stale|current, suffixed with -busy when claude reports itself busy.
restart_targets() {
  local installed self_pids f pid pstart ver status name tmuxref sid cwd state
  installed=$(installed_version)
  self_pids=" $(ancestor_pids | tr '\n' ' ')"

  for f in "$SESSIONS_DIR"/*.json; do
    [ -e "$f" ] || continue
    pid=$(basename "$f" .json)
    case "$pid" in *[!0-9]*) continue ;; esac
    [ -d "/proc/$pid" ] || continue

    pstart=$(json_str "$f" procStart)
    [ "$pstart" = "$(proc_start "$pid")" ] || continue
    case "$self_pids" in *" $pid "*) continue ;; esac

    ver=$(json_str "$f" version)
    status=$(json_str "$f" status)
    name=$(json_str "$f" name)
    tmuxref=$(json_str "$f" tmux)
    sid=$(json_str "$f" sessionId)
    cwd=$(json_str "$f" cwd)

    # Only interactive CLI sessions are ours to restart. Background agents
    # (kind "bg", from --bg / /background / claude agents) register in this
    # same directory, and tmux detection is independent of kind -- a detached
    # agent inherits $TMUX_PANE from whatever pane spawned it, so it can carry
    # a pane reference belonging to something else entirely. jobId/spare mark
    # job-backed and pre-warmed background sessions.
    [ "$(json_str "$f" kind)" = "interactive" ] || continue
    [ "$(json_str "$f" entrypoint)" = "cli" ] || continue
    grep -q '"jobId"' "$f" && continue
    grep -q '"spare":true' "$f" && continue

    # No pane to relaunch in, or nothing to resume.
    [ -z "$tmuxref" ] && continue
    [ -z "$sid" ] && continue

    if [ "$ver" = "$installed" ]; then state="current"; else state="stale"; fi
    # Only "idle" is safe to restart. The other values are claude's own words
    # -- "busy" while it works, "shell" while a backgrounded command is
    # outstanding, and whatever else it grows -- so carry the status through
    # as the hold reason rather than mapping it onto a guessed enum.
    if [ "$status" != "idle" ]; then
      state="${state}-$(printf '%s' "${status:-unknown}" | tr -cd 'a-z_-')"
    elif has_shell_work "$pid"; then
      state="${state}-work"
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$state" "$pid" "$ver" "$name" "$tmuxref" "$sid" "$cwd"
  done
}

cmd_restart_all() {
  # Inert inside the popup. The claude socket inherits this same tmux.conf, so
  # the binding exists there too -- but the sessions it would restart are the
  # popup's own, including the one you are looking at, and the menu would
  # render over the Claude Code UI to ask about it. Restarting is a thing you
  # do from the main tmux, looking at the whole set. Same guard as cmd_select.
  if [[ "$TMUX" == */${SOCKET},* ]]; then
    return
  fi

  local installed targets stale held menu_args=() state pid ver name tmuxref
  installed=$(installed_version)
  targets=$(restart_targets)

  stale=$(echo "$targets" | grep -c '^stale	' || true)
  held=$(echo "$targets" | grep -c '^stale-' || true)

  if [ "$stale" -eq 0 ]; then
    if [ "$held" -gt 0 ]; then
      tmux display-message "Claude ${installed}: all up to date except ${held} held session(s)"
    else
      tmux display-message "Claude ${installed}: all sessions up to date"
    fi
    return 0
  fi

  local name_width=0
  while IFS=$'\t' read -r _ pid ver name _; do
    [ -z "$name" ] && continue
    [ ${#name} -gt "$name_width" ] && name_width=${#name}
  done < <(echo "$targets" | grep -E '^stale(-[a-z_-]+)?	')

  menu_args+=("-↻ Restart (SIGTERM, then resume in place)" "" "")
  while IFS=$'\t' read -r _ pid ver name tmuxref _; do
    [ -z "$pid" ] && continue
    menu_args+=("$(printf '  %-*s  %s  %s' "$name_width" "$name" "$ver" "${tmuxref%%.*}")" "" "")
  done < <(echo "$targets" | grep '^stale	')

  if [ "$held" -gt 0 ]; then
    menu_args+=("" "" "")
    menu_args+=("-⏸ Left alone" "" "")
    while IFS=$'\t' read -r state pid ver name tmuxref _; do
      [ -z "$pid" ] && continue
      menu_args+=("$(printf '  %-*s  %s  %s  (%s)' "$name_width" "$name" "$ver" "${tmuxref%%.*}" "${state#*-}")" "" "")
    done < <(echo "$targets" | grep '^stale-')
  fi

  menu_args+=("" "" "")
  menu_args+=("Restart ${stale} session(s)" "y" "run-shell -b '$SELF restart-run'")
  menu_args+=("Cancel" "Escape" "")

  # "--" and "|| true" for the same reasons as cmd_select above.
  tmux display-menu -T " Claude Code: update to ${installed} " -b heavy \
    -S "fg=${BORDER_COLOR}" -H "bg=${BORDER_COLOR},fg=default" -- "${menu_args[@]}" || true
}

# Restart one session in place.
#   Args: <pid> <version> <name> <tmux ref> <sessionId> <cwd>
#   0 = restarted, 1 = skipped with the pane left exactly as it was.
# Progress goes to stdout; callers decide where that lands.
restart_session() {
  local pid="$1" ver="$2" name="$3" tmuxref="$4" sid="$5" cwd="$6"
  local pane sock cmd waited

  pane="${tmuxref##*.}"
  if ! sock=$(pane_socket "$pane" "$pid"); then
    restart_log "skip ${name} (${pid}): no pane matching ${tmuxref} on either socket"
    return 1
  fi

  # Built before signalling: the session file is gone once claude exits.
  cmd=$(resume_command "$cwd" "$sid")
  restart_log "${name} (${pid}, ${ver}) in ${sock}:${pane}"
  restart_log "  resume: ${cmd}"

  # SIGTERM rather than driving the TUI with /exit. claude's signal handler
  # runs the same graceful shutdown (SessionEnd hooks, transcript flush,
  # session file removed, git worktree unlocked) but never renders the
  # worktree exit dialog -- whose shape varies (Keep/Remove, or a four-option
  # variant when a tmux session is detected) and whose second option discards
  # uncommitted work. Not typing into that menu is the whole point.
  if ! kill -TERM "$pid" 2>/dev/null; then
    restart_log "  skip: SIGTERM failed"
    return 1
  fi

  # Wait for the process to actually go, rather than firing keystrokes at a
  # TUI we cannot see. Anything unexpected -- a prompt, a hung shutdown --
  # times out here and the pane is left untouched for you to look at.
  waited=0
  while [ -d "/proc/$pid" ] && [ "$waited" -lt 150 ]; do
    sleep 0.2
    waited=$((waited + 1))
  done
  if [ -d "/proc/$pid" ]; then
    restart_log "  skip: still alive after 30s, pane left untouched"
    return 1
  fi
  restart_log "  exited after $((waited / 5))s"

  # Let the shell draw its prompt before typing into it.
  waited=0
  while [ "$waited" -lt 25 ]; do
    case "$(tmux -L "$sock" display-message -t "$pane" -p '#{pane_current_command}' 2>/dev/null)" in
      claude | "") sleep 0.2; waited=$((waited + 1)) ;;
      *) break ;;
    esac
  done

  tmux -L "$sock" send-keys -t "$pane" "$cmd" Enter
  restart_log "  sent to ${pane} after $((waited / 5))s"
  return 0
}

cmd_restart_run() {
  local targets restarted=0 skipped=0 state pid ver name tmuxref sid cwd
  targets=$(restart_targets | grep '^stale	' || true)
  [ -z "$targets" ] && { tmux display-message "Claude: nothing to restart"; return 0; }

  # Braces, not a pipe: the counters have to survive the redirect. tmux
  # run-shell parks the pane in view-mode over any stray output, so the whole
  # loop goes to the log instead.
  {
    restart_log "=== restart-all -> $(installed_version)"
    while IFS=$'\t' read -r state pid ver name tmuxref sid cwd; do
      [ -z "$pid" ] && continue
      if restart_session "$pid" "$ver" "$name" "$tmuxref" "$sid" "$cwd"; then
        restarted=$((restarted + 1))
      else
        skipped=$((skipped + 1))
      fi
    done <<< "$targets"
  } >>"$RESTART_LOG" 2>&1

  if [ "$skipped" -gt 0 ]; then
    tmux display-message "Claude: restarted ${restarted}, skipped ${skipped} (${RESTART_LOG})"
  else
    tmux display-message "Claude: restarted ${restarted} session(s)"
  fi
}

# Restart a single session by pid, for trying this out on one target before
# turning it loose on everything. Progress goes to the terminal as well as
# the log, since this one is meant to be run by hand.
cmd_restart_one() {
  local want="$1" found=0 state pid ver name tmuxref sid cwd rc

  if [ -z "$want" ]; then
    echo "Usage: $(basename "$0") restart-one <pid>" >&2
    restart_targets | awk -F'\t' '{printf "  %-9s %-8s %-9s %s\n", $2, $3, $1, $4}' >&2
    return 1
  fi

  while IFS=$'\t' read -r state pid ver name tmuxref sid cwd; do
    [ "$pid" = "$want" ] || continue
    found=1
    case "$state" in
      *-work)
        echo "refusing: ${name} (${pid}) has a monitor or background task running:" >&2
        pgrep -P "$pid" -a 2>/dev/null | grep 'shell-snapshots/snapshot-' | sed 's/^/  /' >&2
        echo "SIGTERM would stop it and resume will not bring it back." >&2
        return 1
        ;;
      *-*)
        echo "refusing: ${name} (${pid}) reports status ${state#*-} -- wait for it to go idle" >&2
        return 1
        ;;
      current)
        echo "note: ${name} (${pid}) is already on $(installed_version); restarting anyway" >&2
        ;;
    esac
    restart_session "$pid" "$ver" "$name" "$tmuxref" "$sid" "$cwd" | tee -a "$RESTART_LOG"
    rc=${PIPESTATUS[0]}
    return "$rc"
  done < <(restart_targets)

  if [ "$found" -eq 0 ]; then
    echo "no live interactive CLI session with pid ${want}" >&2
    return 1
  fi
}

case "${1:-}" in
  select)      cmd_select "$2" "$3" ;;
  popup)       cmd_popup "$2" "$3" ;;
  adopt)       cmd_adopt "$2" "$3" ;;
  cleanup)     cmd_cleanup ;;
  bell)        cmd_bell "$2" ;;
  sync)        cmd_sync "$2" ;;
  kill-window) cmd_kill_window "$2" ;;
  restart-all) cmd_restart_all ;;
  restart-run) cmd_restart_run ;;
  restart-one) cmd_restart_one "$2" ;;
  sidebar-add)        cmd_sidebar_add "$2" ;;
  sidebar-check)      cmd_sidebar_check "$2" ;;
  sidebar-add-all)    cmd_sidebar_add_all ;;
  sidebar-remove-all) cmd_sidebar_remove_all ;;
  *)           echo "Usage: $0 {select|popup|adopt|cleanup|bell|sync|kill-window|restart-all|restart-run|restart-one|sidebar-add|sidebar-add-all|sidebar-remove-all}" >&2; exit 1 ;;
esac

#!/bin/bash
# Sidebar pane for the Claude popup: every agent of every project as a vertical
# list, grouped by project (one claude-socket session per main-socket window),
# with the same state glyphs as the status lines. Runs inside a 28-column pane
# on the left of every popup window (claude.sh adds one per window).
#
# Picking an agent of another project switches the popup to that project's
# session *and* moves the main server to that project's window, so closing the
# popup lands you in the project you were just looking at.
#
# Usage: agent-sidebar.sh            - run the sidebar (needs $TMUX / $TMUX_PANE)
#        agent-sidebar.sh list [session window_id]
#                                    - print the list (used by fzf reload); the optional
#                                      pair renders that window as the current one of its
#                                      session before tmux has switched (pre-switch push)
#        agent-sidebar.sh curpos <session> [window_id]
#                                    - print the fzf actions that mark (and move the cursor
#                                      to) the current window, or the given one
#        agent-sidebar.sh poll <sock> <wrapper_pid>
#                                    - refresh the running fzf when the list changes
#        agent-sidebar.sh refresh <session>
#                                    - push a reload into every sidebar of a session now
#                                      (claude.sh calls it on every window switch)
#
# UI is fzf: j/k or arrows move, Enter or double-click switches to that window
# and puts the cursor back in the agent pane, typing does nothing (filtering is
# off), Esc is ignored. No pointer or marker glyphs: the cursor row is a
# background highlight, and the session's current window is bright bold text
# (ANSI in the list, which fzf keeps even under the cursor) on the same
# highlight, applied through fzf's selection so the cursor can move away from
# it. Rows are padded to the pane width so the highlight spans the whole row.
# fzf listens on a unix socket so pushes arrive the moment something changes;
# list reloads use reload-sync so the old list stays until the new one is ready.
# The current-window marking is always pushed over the socket (the poller's
# first tick does the initial one): a transform() bound to fzf's load event
# would do the same job, but with fzf 0.70 the frame drawn after a transform
# switches mouse reporting off for good, and clicks stop working.

SOCKET=claude
SELF="$HOME/.config/tmux/agent-sidebar.sh"
WIDTH=28

tmx() { tmux -L "$SOCKET" "$@"; }

# 24-bit ANSI from a theme token
ansi() {
  local hex; hex=$(tmx show -gv "$1" 2>/dev/null); hex=${hex#\#}
  [ ${#hex} = 6 ] || { printf ''; return; }
  printf '\e[38;2;%d;%d;%dm' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

session_of_pane() { tmx display -t "$1" -p '#{session_name}'; }

# Sessions in the order of their main-socket windows; orphans (no main window
# any more) last. Prints "<session>\x1f<label>".
sessions_in_order() {
  local live="" idx wid name s label
  while read -r idx wid name; do
    s="win${wid#@}"
    tmx has-session -t "$s" 2>/dev/null || continue
    live+=" $s "
    printf '%s\x1f%s\n' "$s" "$name"
  done < <(tmux -L default list-windows -F '#{window_index} #{window_id} #{window_name}' 2>/dev/null)
  for s in $(tmx list-sessions -F '#{session_name}' 2>/dev/null); do
    case "$live" in *" $s "*) continue ;; esac
    label=$(tmx show -v -t "$s" @orig_window_name 2>/dev/null); label="${label:-$s} (orphan)"
    printf '%s\x1f%s\n' "$s" "$label"
  done
}

# The whole list: a project line per session, then one line per window:
#   "<session>\t-\t<label>"                     project line (Enter = go there)
#   "<session>\t<window_id>\t  <glyph> <index>:<title>"
# The glyph carries its state colour; each session's current window is bright
# bold; everything is padded to the sidebar width (display width, CJK aware).
cmd_list() {
  local ov_session="${1:-}" ov_wid="${2:-}"
  local C_WAIT C_ATTN C_ACT C_OK C_MUTED C_CUR R=$'\e[0m' width
  C_WAIT=$(ansi @t_danger); C_ATTN=$(ansi @t_attention); C_ACT=$(ansi @t_active)
  C_OK=$(ansi @t_ok); C_MUTED=$(ansi @t_fg_muted); C_CUR="$(ansi @t_fg_strong)"$'\e[1m'
  width=$(tmx display -t "${TMUX_PANE:-}" -p '#{pane_width}' 2>/dev/null); width=${width:-$WIDTH}
  local session label wid idx active state bell name title glyph text
  pad() { local w; w=$(printf '%s' "$1" | wc -L); printf '%s%*s' "$1" $(( width > w ? width - w : 0 )) ''; }
  while IFS=$'\x1f' read -r session label; do
    [ -n "$session" ] || continue
    printf '%s\t-\t%s%s%s\n' "$session" "$C_MUTED" "$(pad "$label")" "$R"
    while IFS=$'\x1f' read -r wid idx active state bell name; do
      [ -n "$wid" ] || continue
      if [ "$session" = "$ov_session" ]; then [ "$wid" = "$ov_wid" ] && active=1 || active=0; fi
      # title: the agent pane's terminal title (✳ stripped), else the window name
      title=$(tmx list-panes -t "$wid" -F '#{pane_title}' -f '#{!=:#{@sidebar},1}' | sed -n 's/^✳ //p' | head -1)
      [ -n "$title" ] || title="$name"
      if [ -n "$state" ]; then
        if   [ "$state" = waiting ]; then glyph="${C_WAIT}●"
        elif [ "$bell" = 1 ];        then glyph="${C_ATTN}●"
        elif [ "$state" = busy ];    then glyph="${C_ACT}●"
        else                              glyph="${C_OK}○"; fi
      else
        glyph=" "
      fi
      text=$(pad "  X $idx:$title")   # X stands in for the glyph while measuring
      if [ "$active" = 1 ]; then
        # bright bold text; the glyph keeps its own colour and the brightness resumes after it
        text=${text/X/"$glyph$R$C_CUR"}
        printf '%s\t%s\t%s%s%s\n' "$session" "$wid" "$C_CUR" "$text" "$R"
      else
        text=${text/X/"$glyph$R"}
        printf '%s\t%s\t%s\n' "$session" "$wid" "$text"
      fi
    done < <(tmx list-windows -t "$session" -F $'#{window_id}\x1f#{window_index}\x1f#{window_active}\x1f#{@agent_state}\x1f#{window_bell_flag}\x1f#{window_name}')
  done < <(sessions_in_order)
}

# Switch to a window and focus its agent pane (the one that is not a sidebar).
# The target window's own sidebar is a different fzf whose cursor still sits on
# the window we are leaving; it is moved *before* the switch so the new window
# never appears with a stale cursor. The other sidebars follow through
# claude.sh's session-window-changed hook.
# cmd_go <session> <window_id|-> [from_pane]
# A project line ("-") means that session's current window. Another session:
# move the main server to that project's window, then switch the popup client
# (the one showing the sidebar's own session) to the session.
cmd_go() {
  local session="$1" wid="$2" from="${3:-$TMUX_PANE}" own pane sb sock client
  [ "$wid" = "-" ] && wid=$(tmx display -t "$session" -p '#{window_id}')
  own=$(session_of_pane "$from")
  if [ "$session" != "$own" ]; then
    tmux -L default select-window -t "@${session#win}" 2>/dev/null
    client=$(tmx list-clients -t "$own" -F '#{client_name}' | head -1)
    [ -n "$client" ] && tmx switch-client -c "$client" -t "$session"
  fi
  sb=$(tmx list-panes -t "$wid" -F '#{pane_id}' -f '#{==:#{@sidebar},1}' | head -1)
  sock="/tmp/tmux-$(id -u)/sidebar-${sb#%}.sock"
  [ -n "$sb" ] && [ -S "$sock" ] && curl -s --unix-socket "$sock" -XPOST localhost -d "reload-sync($SELF list $session $wid)+$(cmd_curpos "$session" "$wid")" >/dev/null 2>&1
  tmx select-window -t "$wid"
  pane=$(tmx list-panes -t "$wid" -F '#{pane_id}' -f '#{!=:#{@sidebar},1}' | head -1)
  [ -n "$pane" ] && tmx select-pane -t "$pane"
}

# fzf actions that mark the current window (or the given window id) with the
# selection marker and put the cursor on it.
cmd_curpos() {
  local session="$1" wid="${2:-}" pos
  [ -n "$wid" ] || wid=$(tmx display -t "$session" -p '#{window_id}')
  pos=$(cmd_list | awk -F'\t' -v s="$session" -v w="$wid" '$1==s && $2==w {print NR; exit}')
  printf 'deselect-all+pos(%s)+select' "${pos:-1}"
}

# Window switched: reload every sidebar of the session (the current window is
# part of the list text) and re-mark it. reload-sync keeps the old list on
# screen until the new one is ready. Each fzf listens on
# /tmp/tmux-<uid>/sidebar-<pane number>.sock.
cmd_refresh() {
  local session="$1" p sock action
  action="reload-sync($SELF list)+$(cmd_curpos "$session")"
  for p in $(tmx list-panes -s -t "$session" -F '#{pane_id}' -f '#{==:#{@sidebar},1}' 2>/dev/null); do
    sock="/tmp/tmux-$(id -u)/sidebar-${p#%}.sock"
    [ -S "$sock" ] || continue
    curl -s --unix-socket "$sock" -XPOST localhost -d "$action" >/dev/null 2>&1 &
  done
  wait
}

# Push a reload into fzf whenever the rendered list changes (a state, title or
# window came or went). reload-sync keeps the old list on screen until the new
# one is ready, then the current window is re-marked. Started by the wrapper
# before fzf (not from an fzf execute action: a child left running by execute
# makes fzf drop its mouse reporting about a second later), fully detached
# from the tty, and it exits when the wrapper dies or the socket goes away.
cmd_poll() {
  local sock="$1" wrapper="$2" session prev="" cur i
  session=$(session_of_pane "$TMUX_PANE")
  for i in $(seq 1 50); do [ -S "$sock" ] && break; sleep 0.1; done
  while kill -0 "$wrapper" 2>/dev/null && [ -S "$sock" ]; do
    cur=$(cmd_list)
    if [ "$cur" != "$prev" ]; then
      prev="$cur"
      curl -s --unix-socket "$sock" -XPOST localhost -d "reload-sync($SELF list)+$(cmd_curpos "$session")" >/dev/null 2>&1
    fi
    sleep 1
  done
}

cmd_run() {
  [ -n "$TMUX_PANE" ] || { echo "agent-sidebar: not in a tmux pane" >&2; exit 1; }
  tmx set -p -t "$TMUX_PANE" @sidebar 1
  local session sock
  session=$(session_of_pane "$TMUX_PANE")
  sock="/tmp/tmux-$(id -u)/sidebar-${TMUX_PANE#%}.sock"
  local fg strong muted hl
  fg=$(tmx show -gv @t_fg); strong=$(tmx show -gv @t_fg_strong); muted=$(tmx show -gv @t_fg_muted); hl=$(tmx show -gv @t_bg_highlight)
  local pollpid="" fzfpid=""
  # When the pane is killed tmux sends HUP to the process group. fzf ignores it,
  # so it is run in the background and killed from here; the wrapper then exits
  # instead of looping round and restarting fzf on a dead pty.
  trap 'rm -f "$sock"; [ -n "$pollpid" ] && kill "$pollpid" 2>/dev/null; [ -n "$fzfpid" ] && kill "$fzfpid" 2>/dev/null' EXIT
  trap 'exit 0' HUP INT TERM
  while :; do
    rm -f "$sock"
    [ -n "$pollpid" ] && kill "$pollpid" 2>/dev/null
    setsid "$SELF" poll "$sock" $$ </dev/null >/dev/null 2>&1 &
    pollpid=$!
    cmd_list | fzf \
      --listen="$sock" --ansi --no-input --no-info --no-scrollbar --no-separator --layout=reverse \
      --delimiter=$'\t' --with-nth=3.. --multi --pointer='' --marker='' --gutter=' ' --highlight-line --no-bold --ellipsis='' \
      --color="bg:-1,fg:$fg,bg+:$hl,fg+:$fg,selected-fg:-1,selected-bg:$hl,header:$muted,gutter:-1,border:$muted" \
      --bind='j:down,k:up,tab:ignore,shift-tab:ignore' \
      --bind="enter:execute-silent($SELF go {1} {2} $TMUX_PANE)" \
      --bind="double-click:execute-silent($SELF go {1} {2} $TMUX_PANE)" \
      --bind='esc:ignore,ctrl-c:ignore,ctrl-d:ignore,ctrl-q:ignore' \
      >/dev/null &
    fzfpid=$!
    wait "$fzfpid"; fzfpid=""
    sleep 1   # fzf exited (e.g. killed); come back
  done
}

case "${1:-}" in
  list) cmd_list "$2" "$3" ;;
  go)   cmd_go "$2" "$3" "$4" ;;
  poll) cmd_poll "$2" "$3" ;;
  refresh) cmd_refresh "$2" ;;
  curpos) cmd_curpos "$2" "$3" ;;
  "")   cmd_run ;;
  *)    echo "Usage: $0 [list|go <session> <window_id|-> [from_pane]|poll <sock> <fzf_pid>|refresh <session>|curpos <session> [window_id]]" >&2; exit 1 ;;
esac

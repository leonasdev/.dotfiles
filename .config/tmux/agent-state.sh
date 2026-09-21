#!/bin/bash
# Agent state feed for the tmux status lines.
#
# Usage: agent-state.sh loop | tick
#   loop - run tick once a second forever (started by tmux via #() in status-right
#          on the main server, which keeps it alive while a client is attached)
#   tick - one pass
#
# Source of truth: ~/.claude/sessions/<pid>.json, written by Claude Code. Each
# file carries "status":"busy|idle" and "tmux":"<session>:@<window>.%<pane>",
# the window it runs in on the claude socket (sessions there are named win<N>,
# where N is the main-socket window id the popup belongs to).
#
# Per tick:
#   claude socket, every window   @agent_state = busy | idle | waiting   (unset: no claude here)
#                                  "waiting" is Claude's own report that it needs input
#                                  (question, approval, sandbox/worker request) and holds
#                                  until answered. waitingFor "dialog open" is a UI the
#                                  user opened themselves (/rewind, /model, ...) and is
#                                  treated as idle.
#   claude socket, every session  status rows  = on | 2        (2 when > ROW_SPLIT windows)
#   main socket,   every window   @agent_wait  = agents Claude reports as waiting for input
#                                 @agent_attn  = agents with an unread bell (and not waiting)
#                                 @agent_busy  = agents busy, no unread bell    (unset when 0)
#                                 @agent_idle  = agents idle, no unread bell    (unset when 0)
#                                 (each agent is counted once, in that priority order)
#                                 @agent_dots  = one glyph per agent that needs you or is
#                                                running, wait/attn/busy order; idle agents are
#                                                not drawn (main answers "where do I need to go",
#                                                the popup lists everyone). Styled with @t_*
#                                                tokens (printed via #{E:}), at most MAX_DOTS
#                                                glyphs then "+N"; unset when nothing to show
# Options are only written when the value changes.

SESS_DIR="$HOME/.claude/sessions"
CLAUDE=claude
MAIN=default
ROW_SPLIT=6   # must match the window_index split in tmux.conf's popup status-format
MAX_DOTS=8    # main-socket badge: glyphs shown before collapsing the rest into +N

# dots <wait> <attn> <busy>: the styled glyph string for a main window
dots() {
  local w=${1:-0} a=${2:-0} b=${3:-0} out="" room=$MAX_DOTS n
  n=$(( w < room ? w : room )); [ "$n" -gt 0 ] && out+="#[fg=#{@t_danger},bold]$(printf '●%.0s' $(seq "$n"))";    room=$(( room - n ))
  n=$(( a < room ? a : room )); [ "$n" -gt 0 ] && out+="#[fg=#{@t_attention},bold]$(printf '●%.0s' $(seq "$n"))"; room=$(( room - n ))
  n=$(( b < room ? b : room )); [ "$n" -gt 0 ] && out+="#[fg=#{@t_active}]$(printf '●%.0s' $(seq "$n"))";          room=$(( room - n ))
  n=$(( w + a + b - MAX_DOTS )); [ "$n" -gt 0 ] && out+="#[fg=#{@t_fg_muted}]+$n"
  printf '%s' "$out"
}

# set_count <window_id> <option> <wanted> <current>: write only on change, unset when empty
set_count() {
  [ "$3" = "$4" ] && return
  if [ -n "$3" ]; then tmux -L "$MAIN" set -w -t "$1" "$2" "$3"
  else                 tmux -L "$MAIN" set -wu -t "$1" "$2"; fi
}

tick() {
  local cw
  cw=$(tmux -L "$CLAUDE" list-windows -a -F '#{session_name} #{window_id} #{window_bell_flag} #{@agent_state}' 2>/dev/null) || cw=""

  # window id -> busy|idle, from live session files only
  declare -A want=()
  local f pid tm status
  for f in "$SESS_DIR"/*.json; do
    [ -e "$f" ] || continue
    pid=${f##*/}; pid=${pid%.json}
    kill -0 "$pid" 2>/dev/null || continue
    tm=$(sed -n 's/.*"tmux":"win[0-9]*:\(@[0-9]*\)\.%[0-9]*".*/\1/p' "$f")
    [ -n "$tm" ] || continue
    status=$(sed -n 's/.*"status":"\([a-z]*\)".*/\1/p' "$f")
    if [ "$status" = waiting ] && grep -q '"waitingFor":"dialog open"' "$f"; then status=idle; fi
    want[$tm]=${status:-idle}
  done

  declare -A wait=() busy=() attn=() idle=() nwin=()
  local sname wid flag cur w
  while read -r sname wid flag cur; do
    [ -n "$wid" ] || continue
    w=${want[$wid]:-}
    if [ "$w" != "$cur" ]; then
      if [ -n "$w" ]; then tmux -L "$CLAUDE" set -w -t "$wid" @agent_state "$w"
      else                 tmux -L "$CLAUDE" set -wu -t "$wid" @agent_state; fi
    fi
    nwin[$sname]=$(( ${nwin[$sname]:-0} + 1 ))
    if   [ "$w" = waiting ]; then wait[$sname]=$(( ${wait[$sname]:-0} + 1 ))
    elif [ "$flag" = 1 ];     then attn[$sname]=$(( ${attn[$sname]:-0} + 1 ))
    elif [ "$w" = busy ]; then busy[$sname]=$(( ${busy[$sname]:-0} + 1 ))
    elif [ "$w" = idle ]; then idle[$sname]=$(( ${idle[$sname]:-0} + 1 )); fi
  done <<< "$cw"

  # popup status rows
  local rows
  while read -r sname rows; do
    [ -n "$sname" ] || continue
    # the status option takes on|off|2..5, and reports "on" for a single row
    if [ "${nwin[$sname]:-0}" -gt "$ROW_SPLIT" ]; then w=2; else w=on; fi
    [ "$rows" = "$w" ] || tmux -L "$CLAUDE" set -t "$sname" status "$w"
  done <<< "$(tmux -L "$CLAUDE" list-sessions -F '#{session_name} #{status}' 2>/dev/null)"

  # main-socket counts
  local mw mwid a b i
  local d wt
  mw=$(tmux -L "$MAIN" list-windows -a -F '#{window_id}#{@agent_wait}#{@agent_attn}#{@agent_busy}#{@agent_idle}#{@agent_dots}' 2>/dev/null) || return 0
  # unit separator, not tab: tab is IFS whitespace and would collapse empty fields
  while IFS=$'\x1f' read -r mwid wt a b i d; do
    [ -n "$mwid" ] || continue
    sname="win${mwid#@}"
    set_count "$mwid" @agent_wait "${wait[$sname]:-}" "$wt"
    set_count "$mwid" @agent_attn "${attn[$sname]:-}" "$a"
    set_count "$mwid" @agent_busy "${busy[$sname]:-}" "$b"
    set_count "$mwid" @agent_idle "${idle[$sname]:-}" "$i"
    set_count "$mwid" @agent_dots "$(dots "${wait[$sname]:-0}" "${attn[$sname]:-0}" "${busy[$sname]:-0}")" "$d"
  done <<< "$mw"
}

case "${1:-}" in
  tick) tick ;;
  loop) while :; do tick; echo; sleep 1; done ;;
  *)    echo "Usage: $0 {loop|tick}" >&2; exit 1 ;;
esac

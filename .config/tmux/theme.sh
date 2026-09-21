#!/bin/bash
# tmux theme switcher
#
# Usage: theme.sh <command>
#   apply         - Source themes/current.conf into the calling server and push
#                   tokens into the colour options that cannot take formats
#                   (run from tmux.conf; needs $TMUX)
#   set <name>    - Make themes/<name>.conf current and apply it to every
#                   running server (default + claude)
#   menu          - display-menu listing available themes
#   list          - Print theme names, current one marked with *

DIR="$HOME/.config/tmux/themes"
SELF="$HOME/.config/tmux/theme.sh"
SOCKETS=(default claude)

current_name() {
  local target
  target=$(readlink "$DIR/current.conf" 2>/dev/null) || return 1
  echo "${target%.conf}"
}

# Push tokens into options that reject formats (bad colour: #{@t_x}).
apply_to() {
  local sock="$1"   # socket path
  tmux -S "$sock" source-file "$DIR/current.conf" || return 1
  tmux -S "$sock" set -g  display-panes-colour        "$(tmux -S "$sock" show -gv @t_focus)"
  tmux -S "$sock" set -g  display-panes-active-colour "$(tmux -S "$sock" show -gv @t_info)"
  tmux -S "$sock" set -gw clock-mode-colour           "$(tmux -S "$sock" show -gv @t_ok)"
}

cmd_apply() {
  [ -n "$TMUX" ] || { echo "apply: not inside tmux (no \$TMUX)" >&2; exit 1; }
  apply_to "${TMUX%%,*}"
}

cmd_set() {
  local name="$1"
  [ -f "$DIR/$name.conf" ] || { echo "no such theme: $name" >&2; exit 1; }
  ln -sfn "$name.conf" "$DIR/current.conf"
  local l path
  for l in "${SOCKETS[@]}"; do
    path=$(tmux -L "$l" display -p '#{socket_path}' 2>/dev/null) || continue
    apply_to "$path"
  done
}

cmd_list() {
  local cur f name
  cur=$(current_name)
  for f in "$DIR"/*.conf; do
    name=$(basename "${f%.conf}")
    [ "$name" = current ] && continue
    if [ "$name" = "$cur" ]; then echo "* $name"; else echo "  $name"; fi
  done
}

cmd_menu() {
  local cur f name args=()
  cur=$(current_name)
  for f in "$DIR"/*.conf; do
    name=$(basename "${f%.conf}")
    [ "$name" = current ] && continue
    if [ "$name" = "$cur" ]; then
      args+=("* $name" "" "")
    else
      args+=("  $name" "" "run-shell '$SELF set $name'")
    fi
  done
  tmux display-menu -T " Theme " -- "${args[@]}"
}

case "${1:-}" in
  apply) cmd_apply ;;
  set)   cmd_set "$2" ;;
  list)  cmd_list ;;
  menu)  cmd_menu ;;
  *)     echo "Usage: $0 {apply|set <name>|list|menu}" >&2; exit 1 ;;
esac

function fish_user_key_bindings
  bind -e \cd # unbind ctrl-d
  bind -e \cu # unbind ctrl-u
  bind -e \cp # unbind ctrl-p
  bind \cy accept-autosuggestion
  bind \cb 'cd ..; commandline -f repaint'
  bind \cn 'prevd; commandline -f repaint'
  bind \cs cancel-commandline
  bind \ch backward-kill-path-component # \ch means ctrl+backspace in xterm based terminal-emulator
  bind \cj down-line
  bind \ck up-line

  bind \cp change_directory_with_fzf
end

function change_directory_with_fzf
  set -l selected $(fdfind --type=directory -H . -E .git -E .npm | fzf); commandline -f repaint
  if test -n "$selected"
    cd $selected
  end
end

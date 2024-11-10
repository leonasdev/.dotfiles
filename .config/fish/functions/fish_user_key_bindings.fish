function fish_user_key_bindings
  bind -e \cd # unbind ctrl-d
  bind -e \cu # unbind ctrl-u
  bind -e \cp # unbind ctrl-p
  bind \cy accept-autosuggestion
  bind \cb 'cd ..; omp_repaint_prompt'
  bind \cn 'prevd; omp_repaint_prompt'
  bind \cs cancel-commandline
  bind \ch backward-kill-path-component # \ch means ctrl+backspace in xterm based terminal-emulator

  bind \cp change_directory_with_fzf
end

function change_directory_with_fzf
  if type -q fdfind
    set fd_cmd fdfind # in Ubuntu, fd is installed as fdfind
  else if type -q fd # in Arch Linux, fd is installed as fd
    set fd_cmd fd
  else
    echo "Neither fdfind nor fd can be found."
    return 1
  end
  set -l selected ($fd_cmd --type=directory . . ~/ -H -E .git -E .npm -E .cache -d 3 | fzf); omp_repaint_prompt
  if test -n "$selected"
    cd $selected
  end
end

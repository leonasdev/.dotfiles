function fish_user_key_bindings
  bind -e \cd # unbind ctrl-d
  bind -e \cu # unbind ctrl-u
  bind -e \cp # unbind ctrl-p
  bind \cy accept-autosuggestion
  bind \cb 'cd ..; commandline -f repaint'
  bind \cw 'prevd; commandline -f repaint'
  bind \cs cancel-commandline
  bind \ch backward-kill-path-component # \ch means ctrl+backspace in xterm based terminal-emulator
  bind \cj down-line
  bind \ck up-line

end

function change_directory_with_fzf
  cd $(fdfind --type=directory -H -d=2 . ~ | fzf); commandline -f repaint
end

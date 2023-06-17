function fish_user_key_bindings
  bind -e \cd # unbind ctrl-d
  bind -e \cu # unbind ctrl-u
  bind -e \cp # unbind ctrl-p
  bind \cy accept-autosuggestion
  bind \cb backward-word
  bind \cw forward-word
  bind \cs cancel-commandline
  bind \ch backward-kill-path-component # \ch means ctrl+backspace in xterm based terminal-emulator
  bind \cj down-line
  bind \ck up-line

  bind \cp change_directory_with_fzf
end

function change_directory_with_fzf
  cd $(fdfind -H -d=2 . ~ | fzf)
end

function fish_user_key_bindings
  bind -e \cd # unbind ctrl-d
  bind -e \cu # unbind ctrl-d
  bind \cy accept-autosuggestion
  bind \cb backward-word
  bind \cw forward-word
  bind \cs cancel-commandline
  bind \ch backward-kill-path-component # \ch means ctrl+backspace in xterm based terminal-emulator
  bind \cj down-line
  bind \ck up-line
end

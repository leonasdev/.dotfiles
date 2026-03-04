function fish_user_key_bindings
    bind -e \cd # unbind ctrl-d
    bind -e \cu # unbind ctrl-u
    bind -e \cp # unbind ctrl-p
    bind \ep "" # unbind alt-p
    bind \es "" # unbind alt-s
    bind \ev "" # unbind alt-v
    bind \cy complete
    bind \cb 'cd ..; omp_repaint_prompt'
    bind \cn 'prevd; omp_repaint_prompt'
    bind \cs cancel-commandline
    bind \ch backward-kill-path-component # \ch means ctrl+backspace in xterm based terminal-emulator

    bind \cp fzf_change_directory
    bind \cr fzf_history_search
end

function fzf_change_directory
    set -l fd_cmd
    if type -q fdfind
      set fd_cmd fdfind # in Ubuntu, fd is installed as fdfind
    else if type -q fd # in Arch Linux, fd is installed as fd
      set fd_cmd fd
    else
      echo "Neither fdfind nor fd can be found."
      return 1
    end

    set -l preview_cmd "eza -T -L 1 --icons --group-directories-first {} | head -20"

    set -l selected ($fd_cmd --type=directory . . $HOME -H -E .git -E .npm -E .cache -d 3 | fzf  \
        --height=60% \
        --layout=reverse \
        --border \
        --prompt=(set_color blue)"󰥨 Jump ❯ "(set_color normal) \
        --preview="$preview_cmd");

    omp_repaint_prompt

    if test -n "$selected"
      cd $selected
    end

    commandline -f repaint
end

function fzf_history_search
    history merge 
    
    set -l result (history -z | fzf --read0 \
        --tiebreak=index \
        --query (commandline) \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt=(set_color blue)" History ❯ "(set_color normal))

    if test -n "$result"
        commandline -r $result
    end
    commandline -f repaint
end

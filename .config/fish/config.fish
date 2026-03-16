### --- 1. Path Management ---
fish_add_path "$HOME/.local/bin" \
              "$HOME/go/bin" \
              "$HOME/.cargo/bin" \
              "/usr/local/go/bin"


### --- 2. Environment Variables ---
if type -q nvim
    set -gx EDITOR nvim
else if type -q vim
    set -gx EDITOR vim
else
    set -gx EDITOR vi
end

# fzf colorscheme & default settings
set -gx FZF_DEFAULT_OPTS $FZF_NON_COLOR_OPTS \
    "--color=bg+:-1,bg:-1,spinner:#cc5f29,hl:#caa944" \
    "--color=fg:#808079,header:#5ca8cc,info:#caa944,pointer:#5ca8cc" \
    "--color=marker:#5ca8cc,fg+:#cccca5,prompt:#caa944,hl+:#cc5f29" \
    "--info=inline-right" \
    "--no-scrollbar" \
    "--bind=change:top" \
    "--bind=resize:clear-screen"

### --- 3. Fish Internal Variables ---
set -g fish_greeting ""


### --- 4. Interactive only --- 
if status is-interactive
    # eza / ls
    if type -q eza
        alias l "eza -lg --icons --group-directories-first"
        alias ll "eza -lga --icons --group-directories-first --git"
        # auto generate lt, ltt, lttt, ...
        for i in (seq 10)
            set -l t_string (string repeat -n $i t)
            alias l$t_string="eza --tree -L $i --icons --group-directories-first --git-ignore"
        end
    else
        alias ll "ls -AlF"
        alias l "ls -lF"
    end

    if type -q oh-my-posh # check if oh-my-posh exist
        oh-my-posh init fish --config $HOME/.config/oh-my-posh/leonasdev.omp.json | source
    end
end

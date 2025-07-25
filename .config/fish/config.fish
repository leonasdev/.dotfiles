set fish_greeting ""


command -qv nvim && alias vim nvim

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH
set -gx PATH ~/go/bin $PATH

set -gx nvm_default_version latest

set -x ZELLIJ_AUTO_EXIT true

# fzf colorscheme
set -gx FZF_DEFAULT_OPTS "$FZF_NON_COLOR_OPTS"\
" --color=bg+:-1,bg:-1,spinner:#cc5f29,hl:#caa944"\
" --color=fg:#808079,header:#5ca8cc,info:#caa944,pointer:#5ca8cc"\
" --color=marker:#5ca8cc,fg+:#cccca5,prompt:#caa944,hl+:#cc5f29"

set -x GPG_TTY (tty)

if status is-interactive
# Commands to run in interactive sessions can go here
    # aliases
    alias g git

    alias ls "ls -p -G"
    alias la "ls -a"
    alias ll "ls -lA"
    alias lla "ll -A"

    alias cz chezmoi

    if type -q eza
        alias ls "eza --icons"
        alias lsa "ls -a"
        alias ll "eza -l -g --icons"
        alias lla "ll -a"
    end
    fish_add_path $HOME/.cargo/bin
    fish_add_path /usr/local/go/bin
    if type -q oh-my-posh # check if oh-my-posh exist
        oh-my-posh init fish --config ~/.config/oh-my-posh/leonasdev.omp.json | source
    end
end

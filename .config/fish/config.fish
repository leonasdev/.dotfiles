set fish_greeting ""

# aliases
alias ls "ls -p -G"
alias la "ls -a"
alias ll "ls -l"
alias lla "ll -A"

if type -q exa
alias ll "exa -l -g --icons"
alias lla "ll -a"
end

alias g git

command -qv nvim && alias vim nvim

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

if status is-interactive
# Commands to run in interactive sessions can go here
    oh-my-posh init fish --config ~/.config/oh-my-posh/leonasdev.omp.json| source
end

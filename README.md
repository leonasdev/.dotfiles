# .dotfiles
My personal dotfiles

# Quick Start
```bash
git clone -b master --bare https://github.com/leonasdev/.dotfiles $HOME/.dotfiles
git config --global alias.dotfiles '!git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
git dotfiles config --local status.showUntrackedFiles no
git dotfiles checkout
```

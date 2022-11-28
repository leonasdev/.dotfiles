# .dotfiles
My personal dotfiles

# Prerequisites
## Windows
- [CMake](https://cmake.org/download/)
- [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/zh-hant/downloads/#build-tools-for-visual-studio-2022) (MSVC)

# Quick Start
```bash
git clone -b master --bare https://github.com/leonasdev/.dotfiles $HOME/.dotfiles
git config --global alias.dotfiles '!git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
git dotfiles config --local status.showUntrackedFiles no
git dotfiles checkout
```

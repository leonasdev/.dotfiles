# .dotfiles
My personal dotfiles

# Prerequisites
## Windows
- [CMake](https://cmake.org/download/)
- [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/zh-hant/downloads/#build-tools-for-visual-studio-2022) (MSVC)

## Linux
- CMake
  - `sudo apt install cmake`
- Clang
  - `sudo apt install clang`
- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep#installation)
  ```
    $ curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
    $ sudo dpkg -i ripgrep_13.0.0_amd64.deb
  ```
- [sharkdp/fd](https://github.com/sharkdp/fd#installation)
  - `sudo apt install fd-find`
- npm & node
 - `sudo apt install npm`
 - `curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && sudo apt-get install -y nodejs`

# Quick Start
```bash
bash <(curl https://raw.githubusercontent.com/leonasdev/.dotfiles/master/run.sh)
```

TODO:
- telescope-fzf-native
- gitignore run.sh
- mason
- lsp
- treesitter
- clipboard slow down startup on Ubuntu 20.04
- fish shell

# .dotfiles
My personal dotfiles

## Prerequisites
### Windows
- [CMake](https://cmake.org/download/)
- [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/zh-hant/downloads/#build-tools-for-visual-studio-2022) (MSVC)

### Linux
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
- Neovim
   ```bash
   curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
   chmod u+x nvim.appimage
   ./nvim.appimage

   # If the ./nvim.appimage command fails, try:

   ./nvim.appimage --appimage-extract
   ./squashfs-root/AppRun --version

   # Optional: exposing nvim globally.
   sudo mv squashfs-root /
   sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
   nvim
   ```

## Quick Start
bash:
```bash
bash <(curl -s https://raw.githubusercontent.com/leonasdev/.dotfiles/master/run.sh)
```
fish:
```bash
bash (curl -s https://raw.githubusercontent.com/leonasdev/.dotfiles/master/run.sh | psub)
```

TODO:
- telescope-fzf-native
- gitignore run.sh
- mason
  - should i init to nothing or some default?
- lsp
  - integrate with mason?
- treesitter
  - should i use auto install?
- clipboard slow down startup on some distro
  - caused by no clipboard provider
  - solved: apt install xclip
- fish shell
- colorscheme
  - now using `ishan9299/nvim-solarized-lua` with some manual config
- better way to manage my dotfiles
- prompt theme
- kitty
- win32yank
- nerd font

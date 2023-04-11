# .dotfiles
My personal dotfiles for Ubuntu 20.04 or newer.

## Prerequisites (choose one)
### Bash
Choose one:
- [nvm-sh/nvm](https://github.com/nvm-sh/nvm) (Recommendation)
  ```bash
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  # Restart with a new session
  nvm install node
  ```
- [Node & npm](https://nodejs.org/) (Manually)


### Fish Shell (Recommendation)
- [Fish shell](https://github.com/fish-shell/fish-shell) - The user-friendly command line shell
  ```bash
  sudo apt-add-repository -yu ppa:fish-shell/release-3
  sudo apt install -qqy fish
  
  # Make fish shell default:
  echo /usr/bin/fish | sudo tee -a /etc/shells
  chsh -s /usr/bin/fish
  
  # Restart your session and you will log in with fish.
  ```
**The following commands require execution in fish shell.**
- [jorgebucaran/fisher](https://github.com/jorgebucaran/fisher) - A plugin manager for Fish.
  ```bash
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
  ```
- [jorgebucaran/nvm.fish](https://github.com/jorgebucaran/nvm.fish) - Node.js version manager lovingly made for Fish.
  ```bash
  fisher install jorgebucaran/nvm.fish
  nvm install latest
  set -U nvm_default_version latest
  ```
- [jethrokuan/z](https://github.com/jethrokuan/z) - Pure-fish z directory jumping (optional)
  ```bash
  fisher install jethrokuan/z
  ```
  
## Must Read
**Please use my settings with care and at your own risk. Make sure you understand their effects before applying them.**

Installation will overwrite the following config:
- Neovim
- Fish shell
- oh-my-posh
## Installation
- Bash:
  ```bash
  bash <(curl -s https://raw.githubusercontent.com/leonasdev/.dotfiles/master/install.sh)
  ```
- Fish:
  ```fish
  bash (curl -s https://raw.githubusercontent.com/leonasdev/.dotfiles/master/install.sh | psub)
  ```

TODO:
- colorscheme
  - now using `ishan9299/nvim-solarized-lua` with some manual config
- better way to manage my dotfiles
- kitty
- win32yank
- nerd font

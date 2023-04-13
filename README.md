<div align="center">
<h1>🔸.dotfiles</h1>
My personal dotfiles that include an aesthetic and feature-rich neovim config
</div>

---

- **Shout out to [@Takuya Matsuyama](https://github.com/craftzdog) who inspired my configuration of neovim**
- **Shout out to my Vim mentor [@ThePrimeagen](https://github.com/ThePrimeagen)**
- **Shout out to my Neovim mentor [@tjdevries](https://github.com/tjdevries)**

# 💫Showcase
![Screenshot from 2023-04-14 03-02-50](https://user-images.githubusercontent.com/39915562/231865254-0917e7bc-12a2-40e9-9138-58da6e0d1d54.png)
![Screenshot from 2023-04-14 02-32-54](https://user-images.githubusercontent.com/39915562/231860282-b3aead77-8a03-4fe7-a9fd-6ab4d3c84977.png)
![Screenshot from 2023-04-14 03-07-44](https://user-images.githubusercontent.com/39915562/231859536-1a58c06b-00aa-4456-aa05-5b7f592c2861.png)

# ✨Features
Neovim:
- Blazingly fast startup times by do a lot of lazy-loading with - [lazy.nvim](https://github.com/folke/lazy.nvim)
- Language Server Protocol with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- LSP servers, DAP servers, linters, and formatters manager with [mason.nvim](https://github.com/williamboman/mason.nvim)
- Autocompletion with [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- Aesthetic Colorscheme & Statusline with [nvim-solarized-lua](https://github.com/ishan9299/nvim-solarized-lua), [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- Formatting and Linting with [null-ls.nvim](https://github.com/jose-elias-alvarez/null-ls.nvim)
- Syntax highlighting with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Fuzzy finding with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Git integration with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim), [vim-fugitive](https://github.com/lewis6991/gitsigns.nvim)

# 🚀Getting Started
## ❗Must Read
**Please use my settings with care and at your own risk. Make sure you understand their effects before applying them.**

Installation will overwrite the following's config:
- Neovim
- Fish shell
- oh-my-posh

## ⚡️Requirements
1. Nerd Fonts:
    - Any Nerd Font is required to display the glyph correctly.
    - [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts)
    - **[JetBrains Mono NL](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/JetBrainsMono/NoLigatures) is recommended.**

2. Node (>=16.20.0) & Npm:
    - Bash
      - Manually install [Node & npm](https://nodejs.org/) or via node version manager: [nvm-sh/nvm](https://github.com/nvm-sh/nvm) (Recommendation):
        ```bash
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
        # Restart with a new session
        nvm install node
        ```
    - **Fish Shell (Recommendation)**
      - [Fish shell](https://github.com/fish-shell/fish-shell) - The user-friendly command line shell
        ```bash
        sudo apt-add-repository -yu ppa:fish-shell/release-3
        sudo apt install -qqy fish

        # Make fish shell default:
        echo /usr/bin/fish | sudo tee -a /etc/shells
        chsh -s /usr/bin/fish

        # Restart session and you will log in with fish.
        ```
      **The following commands require execution in fish shell:**
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

## 📦Installation
- Bash:
  ```bash
  bash <(curl -s https://raw.githubusercontent.com/leonasdev/.dotfiles/master/install.sh)
  ```
- Fish:
  ```fish
  bash (curl -s https://raw.githubusercontent.com/leonasdev/.dotfiles/master/install.sh | psub)
  ```

- <details><summary>WSL 2 User Only</summary>

  To use the Windows clipboard from within WSL, [`win32yank.exe`](https://github.com/equalsraf/win32yank) has to be on our `$PATH`. (e.g. `C:\Windows\System32\`)

</details>

## ✅TODO:
- [ ] Add `nvim-dap` support
- [ ] Improve the which-key config
- [ ] Colorscheme
  - Curretlly using `ishan9299/nvim-solarized-lua` with some manual config
  - Considering make a own colorscheme
- [ ] A better way to manage my dotfiles, instead of using `git bare repository`
  - GNU stow?
- [ ] Add my kitty config

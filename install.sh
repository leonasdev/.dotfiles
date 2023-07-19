#!/usr/bin/bash

# COLORS
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
NC=$(tput sgr0)
BOLD=$(tput bold)

# VARIABLES
declare -r GIT_BRANCH="${GIT_BRANCH:-"master"}"
declare -r GIT_REMOTE="${GIT_REMOTE:-leonasdev/.dotfiles}"
declare -r NVIM_DIR="${NVIM_DIR:-"$(which nvim)"}"
declare -r INSTALL_PREFIX="${INSTALL_PREFIX:-"$HOME/.local"}"
declare -r XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -r XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
declare -r RUNTIME_DIR="${RUNTIME_DIR:-"$XDG_DATA_HOME"}"
declare -r CONFIG_DIR="${CONFIG_DIR:-"$XDG_CONFIG_HOME"}"
declare -r PACK_DIR="$RUNTIME_DIR/nvim/site/pack"

# MAIN
function main() {
  sudo echo -e "${BOLD}${BLUE}Welcome to leonasdev's dotfiles installation!\n${NC}"
  check_tput_installed
  pre_check
  check_system_deps
  if command -v nvim &>/dev/null; then
    check_neovim_version
  fi

  # check if user wnat backup neovim config, otherwise it will overwrite it
  if [ -d "$HOME/.config/nvim" ] && ! [ -z "$(ls -A $HOME/.config/nvim)" ]; then
    echo "${BOLD}${YELLOW}Destination path $HOME/.config/neovim already exists and is not an empty directory.${NC}"
    while [ true ]; do
      echo -e "Backup your current ${BOLD}Neovim${NC} config?"
      read -p $'\e[33m[y/n]\e[0m: ' yn
      case $yn in
          [Yy]* ) isBackup=$(backup_old_config);break;;
          [Nn]* ) break;;
          * ) echo "${BOLD}Please answer ${YELLOW}y${NC}${BOLD} or ${YELLOW}n${NC}${BOLD}.${NC}";;
      esac
    done
  fi

  detect_platform
  remove_neovim_config
  clone_and_checkout_repo
  install_deps
  post_install
  msg "${BOLD}${GREEN}\n\n\n\n\nInstallation Successful !\n${NC}" 1
  if [ "$isBackup" ]; then
    echo "${BOLD}${GREEN}You can find your backup config under ${CONFIG_DIR}/nvim.bak${NC}"
  fi
  echo -e "${BOLD}\nNow you can manage your dotfiles by using\n- ${GREEN}git dotfiles${NC}\ncommand.\n"
  echo -e "${BOLD}${YELLOW}\nPlease restart your shell.${NC}\n"
}

function pre_check() {
  if [ -d "$HOME/.dotfiles" ] && ! [ -z "$(ls -A $HOME/.dotfiles)" ]; then
    echo "${BOLD}${YELLOW}Destination path $HOME/.dotfiles already exists and is not an empty directory.${NC}"
    echo "${BOLD}${RED}Installation failed.${NC}"
    exit 1
  fi
  while [ true ]; do
    echo -e "**${BOLD}${RED}Installation will override your current ${GREEN}[neovim, fish, oh-my-posh] ${RED}configuration!${NC}**"
    echo -e "${BOLD}${YELLOW}Continue installation?"
    read -p $'\e[33m[y/n]\e[0m: ' yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 1;break;;
        * ) echo "${BOLD}Please answer ${YELLOW}y${NC}${BOLD} or ${YELLOW}n${NC}${BOLD}.${NC}";;
    esac
  done
}

function post_install() {
  echo -e "${BOLD}${BLUE}Removing install.sh...${NC}"
  rm install.sh
  echo -e "${BOLD}${GREEN}Done${NC}"

  echo -e "${BOLD}${BLUE}Removing README.md...${NC}"
  rm README.md
  echo -e "${BOLD}${GREEN}Done${NC}"
}

function check_neovim_version() {
  msg "${BOLD}Checking Neovim version... ${NC}" "1"
  regex="^NVIM v"
  nvim_ver=$(nvim --version | grep "$regex")
  nvim_ver="${nvim_ver/NVIM v/""}"
  nvim_ver="${nvim_ver:0:3}"
  required_ver="0.9"

  if (( $(echo "$nvim_ver < $required_ver" |bc -l) )); then
    echo -e "${BOLD}${RED}[ERROR]: Neovim version needs to greater then 0.9.0 !${NC}"
    exit 1
  else
    echo -e "${BOLD}${GREEN}Neovim version is greater than 0.9.0${NC}"
  fi
}

function clone_and_checkout_repo() {
  msg "${BOLD}Cloning & checkout dotfiles... ${NC}" "1"
  if ! git clone --branch "$GIT_BRANCH" --bare "https://github.com/${GIT_REMOTE}" "$HOME/.dotfiles"; then
    echo "Failed to clone repository. Installation failed."
    exit 1
  else
    git config --global alias.dotfiles '!git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
    git dotfiles config --local status.showUntrackedFiles no
    git dotfiles checkout -f
  fi
  echo -e "${GREEN}${BOLD}Done${NC}"
}

function remove_neovim_config() {
  cd $HOME
  msg "${BOLD}${YELLOW}Removing current Neovim configuration... ${NC}"
  rm -rf "$RUNTIME_DIR/nvim"
  rm -rf "$CONFIG_DIR/nvim"
  echo -e "${GREEN}${BOLD}Done${NC}"
}

function print_missing_dep_msg() {
  if [ "$#" -eq 1 ] && [ "$1" == "neovim" ] && [ "$OS" == "Darwin" ]; then
    echo -e "${BOLD}${RED}[ERROR]: Unable to find neovim dependency${NC}"
    echo -e "${BOLD}Please install it first and re-run the installer.${NC}"
    echo -e "${BOLD}You need to install latest nightly version. Use: brew install --HEAD neovim${NC}\n"
  elif [ "$#" -eq 1 ] && [ "$1" == "neovim" ]; then
    echo -e "${BOLD}${RED}[ERROR]: Unable to find neovim dependency${NC}"
    echo -e "${BOLD}Please install it first and re-run the installer.${NC}\n"
    echo -e "${BOLD}Highly recommend install Neovim from appimage or build from source to get the latest version.${NC}\n"
  elif [ "$#" -eq 1 ]; then
    echo -e "${BOLD}${RED}[ERROR]: Unable to find dependency [$1]${NC}"
    echo -e "${BOLD}Please install it first and re-run the installer. Try: $RECOMMEND_INSTALL $1${NC}\n"
  else
    local cmds
    cmds=$(for i in "$@"; do echo "$RECOMMEND_INSTALL $i"; done)
    printf "${BOLD}${RED}[ERROR]: Unable to find dependencies [%s]${NC}" "$@"
    printf "Please install any one of the dependencies and re-run the installer. Try: \n%s\n" "$cmds"
  fi
}

function msg() {
  local text="$1"
  local flag="$2"
  local line="$3"
  local div_width="80"

  # Render line
  if [ "$line" != "0" ]; then 
    printf "%${div_width}s\n" ' ' | tr ' ' -
  fi

  # Render text
  if [ "$flag" == "1" ]; then 
    echo -e "$text"
  else
    echo -n "$text"
  fi
}

function backup_old_config() {
  msg "${BOLD}Backing up your current Neovim configuration...${NC}" "1"

  mkdir -p "$CONFIG_DIR/nvim" "$CONFIG_DIR/nvim.bak"
  if command -v rsync &>/dev/null; then
    rsync --archive -hh --partial --progress --cvs-exclude \
      --modify-window=1 "$CONFIG_DIR/nvim"/ "$CONFIG_DIR/nvim.bak"
  else
    OS="$(uname -s)"
    case "$OS" in
      Linux | *BSD)
        cp -r "$CONFIG_DIR/nvim/"* "$CONFIG_DIR/nvim.bak/."
        ;;
      Darwin)
        cp -R "$CONFIG_DIR/nvim/"* "$CONFIG_DIR/nvim.bak/."
        ;;
      *)
        echo "OS $OS is not currently supported."
        false
        return $?
        ;;
    esac
  fi
  true
  return $?
}

function check_system_deps() {
  if ! command -v npm &>/dev/null; then
    print_missing_dep_msg "npm"
    exit 1
  fi
  if ! command -v node &>/dev/null; then
    print_missing_dep_msg "node"
    exit 1
  fi
  if ! command -v git &>/dev/null; then
    print_missing_dep_msg "git"
    exit 1
  fi
}

function install_deps() {
  mkdir -p .cache
  echo -e "${BOLD}${BLUE}Updating apt...${NC}"
  sudo apt update -qq
  echo -e "${GREEN}${BOLD}Done${NC}"
  if ! command -v bc &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing bc...${NC}"
    sudo apt install -qqy bc
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v nvim &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing Neovim 0.10.0 ...${NC}"
    sudo apt install -qqy software-properties-common
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt update -qq
    sudo apt install -qqy neovim
    echo -e "${GREEN}${BOLD}Done${NC}"
  else
    check_neovim_version
  fi
  if ! command -v curl &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing curl...${NC}"
    sudo apt install -qqy curl
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v wget &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing wget...${NC}"
    sudo apt install -qqy wget
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v clang &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing clang...${NC}"
    sudo apt install -qqy clang
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v make &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing make...${NC}"
    sudo apt install -qqy make
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v fdfind &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing fd-find...${NC}"
    sudo apt install -qqy fd-find
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v rg &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing ripgrep...${NC}"
    sudo apt install -qqy ripgrep
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v xclip &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing xclip...${NC}"
    sudo apt install -qqy xclip
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v unzip &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing unzip...${NC}"
    sudo apt install -qqy unzip
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v cargo &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing rustup...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -qy
    source $HOME/.cargo/env
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v go &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing golang...${NC}"
    sudo rm -rf /usr/local/go
    curl -sSL https://go.dev/dl/go1.20.3.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile
    echo "Added /usr/local/go/bin to .bashrc and .profile"
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  # if ! command -v tree-sitter &>/dev/null; then
  #   echo -e "${BOLD}${BLUE}Installing tree-sitter-cli, it may take a little while...${NC}"
  #   cargo install -q tree-sitter-cli
  #   echo -e "${GREEN}${BOLD}Done${NC}"
  # fi
  if ! command -v exa &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing exa... (could take a while)${NC}"
    cargo install -q exa
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v python3-venv &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing python3-venv...${NC}"
    sudo apt install -qqy python3-venv
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
  if ! command -v oh-my-posh &>/dev/null; then
    echo -e "${BOLD}${BLUE}Installing oh-my-posh...${NC}"
    sudo wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
    sudo chmod +x /usr/local/bin/oh-my-posh
    echo 'eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/leonasdev.omp.json)"' >> $HOME/.bashrc
    echo 'eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/leonasdev.omp.json)"' >> $HOME/.profile
    echo "Added eval oh-my-posh to .bashrc and .profile"
    echo -e "${GREEN}${BOLD}Done${NC}"
  fi
}

function detect_platform() {
  msg "${BOLD}Detecting operating system... ${NC}"
  OS="$(uname -s)"
  case "$OS" in
    Linux)
      if [ -f "/etc/arch-release" ] || [ -f "/etc/artix-release" ]; then
        RECOMMEND_INSTALL="sudo pacman -S"
      elif [ -f "/etc/fedora-release" ] || [ -f "/etc/redhat-release" ]; then
        RECOMMEND_INSTALL="sudo dnf install -y"
      elif [ -f "/etc/gentoo-release" ]; then
        RECOMMEND_INSTALL="emerge install -y"
      else # assume debian based
        RECOMMEND_INSTALL="sudo apt install -y"
      fi
      ;;
    FreeBSD)
      RECOMMEND_INSTALL="sudo pkg install -y"
      ;;
    NetBSD)
      RECOMMEND_INSTALL="sudo pkgin install"
      ;;
    OpenBSD)
      RECOMMEND_INSTALL="doas pkg_add"
      ;;
    Darwin)
      RECOMMEND_INSTALL="brew install"
      ;;
    *)
      echo -e "${BOLD}${RED}OS $OS is not currently supported.${NC}"
      exit 1
      ;;
  esac
  echo -e "${BOLD}\nOS detected: ${BLUE}$OS${NC}"
  echo -e "${GREEN}${BOLD}Done${NC}"
}

function check_tput_installed() {
  if ! command -v tput &>/dev/null; then
    print_missing_dep_msg "tput"
    exit 1
  fi
}

main

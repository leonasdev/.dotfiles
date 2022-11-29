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
  echo -e "${BOLD}${BLUE}Welcome to leonasdev's dotfiles installation!${NC}"
  check_tput_install
  detect_platform
  check_system_deps
  check_neovim_version
  echo -e "${BOLD}${YELLOW}Installation will override your current configuration!${NC}\n"
  
  while [ true ]; do
    echo -e "Do you wish to backup your current ${BOLD}Neovim${NC} config?"
    read -p $'\e[33m[y/n]\e[0m: ' yn
    case $yn in
        [Yy]* ) backup_old_config;break;;
        [Nn]* ) break;;
        * ) echo "${BOLD}Please answer ${YELLOW}y${NC}${BOLD} or ${YELLOW}n${NC}${BOLD}.${NC}";;
    esac
  done

  while [ true ]; do
    msg
    read -p $'Do you wish to install dotfiles now? \e[33m[y/n]\e[0m: ' yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "${BOLD}Please answer ${YELLOW}y${NC}${BOLD} or ${YELLOW}n${NC}${BOLD}.${NC}";;
    esac
  done

  remove_neovim_config
  clone_repo
  # install_neovim_packer
  # setup_neovim_plugin
  finish
}

function finish() {
  msg "${BOLD}${GREEN}Installation Successfully!${NC}" 1
  echo -e "${BOLD}Now you can manage your dotfiles by using \"git dotfiles\" command.${NC}\n"
}

function check_neovim_version() {
  msg "${BOLD}Checking Neovim version... ${NC}" "1"
  regex="^NVIM v"
  nvim_ver=$(nvim --version | grep "$regex")
  nvim_ver="${nvim_ver/NVIM v/""}"
  nvim_ver="${nvim_ver:0:3}"
  required_ver="0.8"

  if (( $(echo "$nvim_ver < $required_ver" |bc -l) )); then
    echo -e "${BOLD}${RED}[ERROR]: Neovim version needs to greater then 0.8.0 !${NC}"
    exit 1
  else
    echo -e "${BOLD}${GREEN}Neovim version is greater than 0.8.0${NC}"
  fi
}

# function setup_neovim_plugin() {
#   msg "${BOLD}Moving to Neovim configuration directory... ${NC}"
#   cd $CONFIG_DIR/nvim
#   echo "${GREEN}${BOLD}Done${NC}"
#
#   msg "${BOLD}Installing plugins...${NC}" 1
#   nvim -c 'autocmd User PackerComplete quitall' \
#     -c 'PackerSync'
#   msg "${BOLD}${GREEN}Done${NC}" 1 0
#
#   msg "${BOLD}${GREEN}Packer setup complete!${NC}" 1
# }

# function install_neovim_packer() {
#   msg "${BOLD}Installing Neovim Packer... ${NC}\n"
#   if [ -e "$PACK_DIR/packer/start/packer.nvim" ]; then
#     msg "${BOLD}${GREEN}Packer already installed!${NC}"
#     echo -e
#   else
#     if ! git clone --depth 1 "https://github.com/wbthomason/packer.nvim" \
#       "$PACK_DIR/packer/start/packer.nvim"; then
#       msg "${BOLD}${RED}Failed to clone Packer. Installation failed.${NC}"
#       exit 1
#     fi
#   fi
# }

function clone_repo() {
  msg "${BOLD}Cloning dotfiles... ${NC}" "1"
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
  msg "${BOLD}Removing current Neovim configuration... ${NC}"
  rm -rf "$RUNTIME_DIR/nvim"
  rm -rf "$CONFIG_DIR/nvim"
  echo -e "${GREEN}${BOLD}Done${NC}"
}

function print_missing_dep_msg() {
  if [ "$#" -eq 1 ] && [ "$1" == "neovim" ] && [ "$OS" == "Darwin" ]; then
    echo -e "${BOLD}${RED}[ERROR]: Unable to find neovim dependency${NC}"
    echo -e "${BOLD}Please install it first and re-run the installer.${NC}"
    echo -e "${BOLD}You need to install latest nightly version. Use: brew install --HEAD neovim${NC}\n"
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
        ;;
    esac
  fi
  echo "${BOLD}${GREEN}Backup operation complete! ${GREEN}You can find it under ${CONFIG_DIR}/nvim.bak${NC}"
}

function check_system_deps() {
  if ! command -v npm &>/dev/null; then
    print_missing_dep_msg "npm"
    exit 1
  fi
  if ! command -v git &>/dev/null; then
    print_missing_dep_msg "git"
    exit 1
  fi
  if ! command -v nvim &>/dev/null; then
    print_missing_dep_msg "neovim"
    exit 1
  fi
  if ! command -v fzf &>/dev/null; then
    print_missing_dep_msg "fzf"
    exit 1
  fi
  if ! command -v clang &>/dev/null; then
    print_missing_dep_msg "clang"
    exit 1
  fi
}

function detect_platform() {
  msg "${BOLD}Detecting platform for managing any additional neovim dependencies... ${NC}"
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
  echo -e "${BOLD}\nOS detected: $OS${NC}"
  echo -e "${GREEN}${BOLD}Done${NC}"
}

function check_tput_install() {
  if ! command -v tput &>/dev/null; then
    print_missing_dep_msg "tput"
    exit 1
  fi
}

main

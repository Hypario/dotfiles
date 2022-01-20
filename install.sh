#!/usr/bin/env bash
set -euo pipefail

if [ $(basename "`pwd`") != "dotfiles" ]; then
	echo "Please call the script in the dotfiles directory or call the directory dotfiles"
	exit 1
fi

source helpers.sh

echo "This script will modify your home directory"
prompt  "Are you sure you want to continue ? (y/n) " choice
choice=${choice,,} #tolower

if [[ "$choice" =~ ^(yes|y)$ ]]; then

	if [ ! $(pwd) == "$HOME/dotfiles" ]; then
		info "symlink dotfile folder"
		ln -sf $(pwd) "$HOME/dotfiles"
		success "done"
	fi

	# update
	info "updating your system if needed"
	sudo apt update && sudo apt upgrade -y
	success "done"

	# install tools
	info "downloading needed tools if not installed"
	sudo apt install curl vim zsh git -y
	success "done"

	# install tmux
	prompt "Install tmux ? (y/n) " answer_tmux
	answer_tmux=${answer_tmux,,}
	if [[ "$answer_tmux" =~ ^(yes|y)$ ]]; then
		info "installing tmux"
		sudo apt install tmux
		success "tmux installed"	
	fi

	# install vscodium
	prompt "Install vscodium ? (y/n) " answer_vscodium
	answer_vscodium=${answer_vscodium,,}
	if [[ "$answer_vscodium" =~ ^(yes|y)$ ]]; then
		info "installing vscodium"
		wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg
		echo 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' | sudo tee --append /etc/apt/sources.list.d/vscodium.list
		sudo apt update && sudo apt install codium -y
		success "vscodium installed"
	fi
	# install jetbrains toolbox
	prompt "Install jetbrains toolbox ? (y/n) " answer_toolbox
	answer_toolbox=${answer_toolbox,,}
	if [[ "answer_toolbox" =~ ^(yes|y)$ ]]; then
		info "installing jetbrains toolbox"
		curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
		success "jetbrains toolbox installed"
	fi

	# install nvm
	prompt "Install nvm ? (y/n) " answer_nvm
	answer_nvm=${answer_nvm,,}
	if [[ "$answer_nvm" =~ ^(yes|y)$ ]]; then
		info "installing nvm"
		wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
		success "nvm installed"
	fi

	# installing oh-my-zsh
	prompt "Install oh-my-zsh ? (y/n) " answer_omz
	answer_omz=${answer_omz,,}
	if [[ "$answer_omz" =~ ^(yes|y)$ ]]; then
		info "install oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
		success "oh-my-zsh installed"

		info "installing font for zsh theme"
		sudo apt install fonts-powerline
		success "font installed"

		chsh -s $(which zsh)
	fi

	# installing zsh-autosuggestions
	prompt "Install zsh-autossuggestions ? (y/n) " answer_autosugg
	answer_autosugg=${answer_autosugg}
	if [[ "$answer_autosugg" =~ ^(yes|y)$ ]]; then
		info "install zsh-autossuggestions"
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
		success "zsh-autossugestions installed"
	fi

	# install discord
	prompt "Install discord ? (y/n) " answer_discord
	answer_discord=${answer_discord,,}
	if [[ "$answer_discord" =~ ^(yes|y)$ ]]; then
		info "installing discord"
		TEMP_DEB="$(mktemp)"
		wget -O "$TEMP_DEB" 'https://discord.com/api/download?platform=linux&format=deb' | sudo dpkg -i "$TEMP_DEB"
		rm -rf "$TEMP_DEB"
		success "discord installed"
	fi

	symlinker

	# install php
	prompt "Install php ? (y/n) " answer_php
	answer_php=${answer_php,,}
	if [[ "$answer_php" =~ ^(yes|y)$ ]]; then
		info "installing php"
		
		sudo apt install software-properties-common
		sudo add-apt-repository ppa:ondrej/php
		sudo apt install php8.0 php8.0-pgsql php8.0-common php8.0-xdebug php8.0-zip php8.0-curl php8.0-cli
		
		success "php installed"
	fi
fi

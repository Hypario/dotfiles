#!/usr/bin/env bash
set -euo pipefail

if [ $(basename "`pwd`") != "dotfiles" ]; then
	echo "Please call the script in the dotfiles directory or call the directory dotfiles"
	exit 1
fi

source helpers.sh

confirm() {
	local __var=$1
	prompt "$2" "$__var"
	local value=${!__var,,} # tolower
	[[ "$value" =~ ^(yes|y)$ ]]
}

echo "This script will modify your home directory"

if confirm choice "Are you sure you want to continue ? (y/n) "; then

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
	sudo apt install curl vim zsh git keyutils golang-docker-credential-helpers -y

	info "install bitwarden-cli, which is required for secrets management"
	sudo snap install bw
	success "done"

	# install vscodium
	if confirm answer "Install vscode ? (y/n) "; then
		info "installing vscode"
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
		rm -f packages.microsoft.gpg

		sudo apt install apt-transport-https
		sudo apt update
		sudo apt install code

		success "vscode installed"
		source vscode/configure.sh
	fi
	# install jetbrains toolbox
	if confirm answer "Install jetbrains toolbox ? (y/n) "; then
		info "installing jetbrains toolbox"
		curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
		success "jetbrains toolbox installed"
	fi

	# install nvm
	if confirm answer "Install nvm ? (y/n) "; then
		info "installing nvm"
		wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
		success "nvm installed"
	fi

	# installing oh-my-zsh
	if confirm answer "Install oh-my-zsh ? (y/n) "; then
		info "install oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
		success "oh-my-zsh installed"

		info "installing font for zsh theme"
		sudo apt install fonts-powerline
		success "font installed"

		chsh -s $(which zsh)
	fi

	# installing zsh-autosuggestions
	if confirm answer "Install zsh-autossuggestions ? (y/n) "; then
		info "install zsh-autossuggestions"
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
		success "zsh-autossugestions installed"
	fi

	# install discord
	if confirm answer "Install discord ? (y/n) "; then
		info "installing discord"
		TEMP_DEB="$(mktemp)"
		wget -O "$TEMP_DEB" 'https://discord.com/api/download?platform=linux&format=deb' && sudo dpkg -i "$TEMP_DEB"
		rm -rf "$TEMP_DEB"
		success "discord installed"
	fi

	symlinker

	# install php
	if confirm answer "Install php ? (y/n) "; then
		info "installing php"
		
		sudo apt install software-properties-common
		sudo add-apt-repository ppa:ondrej/php
		sudo apt install php8.0 php8.0-pgsql php8.0-common php8.0-xdebug php8.0-zip php8.0-curl php8.0-cli
		
		success "php installed"
	fi
fi

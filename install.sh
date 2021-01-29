#!/usr/bin/env bash
set -euo pipefail

if [ $(basename "`pwd`") != "dotfiles" ]; then
	fail "Please call the script in the dotfiles directory or call the directory dotfiles"
	exit 1
fi

source helpers.sh

echo "This script will modify your home directory"
read -p "Are you sure you want to continue ? (y/n) " choice

if [ $choice == "y" ]; then

	if [ ! $(pwd) == "$HOME/dotfiles" ]; then
		info "symlink dotfile folder"
		ln -sf $(pwd) "$HOME/dotfiles"
		success "done"
	fi

	sudo apt update && sudo apt upgrade -y
	sudo apt install curl vim zsh -y

	if [ ! command -v git ]; then
		info "installing git"
		sudo apt install git -y
		success "done"
	fi

	# install vscodium
	read -p "Install vscodium ? (y/n) " answer_vscodium
	if [ $answer_vscodium == "y" ]; then
		info "installing vscodium"
		wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg
		echo 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' | sudo tee --append /etc/apt/sources.list.d/vscodium.list
		sudo apt update && sudo apt install codium -y
		success "done"
	fi

	# install nvm
	read -p "Install nvm ? (y/n) " answer_nvm
	if [ $answer_nvm == "y" ]; then
		info "installing nvm"
		wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
		success "done"
	fi

	# installing oh-my-zsh
	read -p "Install oh-my-zsh ? (y/n) " answer_omz
	if [ $answer_omz == "y" ]; then
		info "install oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -unattended
		success "done"

		info "installing font for zsh theme"
		sudo apt install fonts-powerline
		success "done"
	fi

	# installing zsh-autosuggestions
	read -p "Install zsh-autossuggestions ? (y/n) " answer_autosugg
	if [ $answer_autosugg == "y" ]; then
		info "install zsh-autossuggestions"
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
		success "done"
	fi

	# install discord
	read -p "Install discord ? (y/n) " answer_discord
	if [ $answer_discord == "y" ]; then
		info "installing discord"
		TEMP_DEB="$(mktemp)"
		wget -O "$TEMP_DEB" 'https://discord.com/api/download?platform=linux&format=deb' | sudo dpkg -i "$TEMP_DEB"
		rm -rf "$TEMP_DEB"
		success "done"
	fi

	info "symlinking all dotfiles"
	symlinker
	success "done"
fi

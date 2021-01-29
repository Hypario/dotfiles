#!/usr/bin/env bash
set -euo pipefail

echo "This script will modify your home directory"
read -p "Are you sure you want to continue ? (y/n) " choice

if [ $choice == "y" ]; then

	if [ ! $(pwd) == "$HOME/dotfiles" ]; then
		echo "symlink dotfile folder"
		ln -sf $(pwd) "$HOME/dotfiles"
	fi

	sudo apt update && sudo apt upgrade
	sudo apt install curl vim -y

	if [ ! command -v git ]; then
		echo "installing git"
		sudo apt install git -y
	fi

	# copy zshrc
	echo "copy zshrc"
	if [ -f $HOME/.zshrc ]; then
		rm $HOME/.zshrc
	fi
	if [ -f $HOME/.zshrc.pre-oh-my-zsh ]; then
		rm $HOME/.zshrc.pre-oh-my-zsh
	fi
	cp $HOME/dotfiles/.zshrc $HOME/.zshrc

	# install vscodium
	wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg

	# install nvm
	wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash

	# installing oh-my-zsh
	echo "install oh-my-zsh"
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -unattended

	# installing zsh-autosuggestions
	echo "install zsh-autossuggestions"
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

	echo "installing font for zsh theme"
	sudo apt install fonts-powerline

	# install discord
	TEMP_DEB="$(mktemp)"
	wget -O "$TEMP_DEB" 'https://discord.com/api/download?platform=linux&format=deb' | sudo dpkg -i "$TEMP_DEB"
	rm -rf "$TEMP_DEB"
fi

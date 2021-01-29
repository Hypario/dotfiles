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

	# install vscodium
	prompt "Install vscodium ? (y/n) " answer_vscodium
	answer_vscodium=${answer_vscodium,,}
	if [[ "$answer_vscodium" =~ ^(yes|y)$ ]]; then
		info "installing vscodium"
		wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg
		echo 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' | sudo tee --append /etc/apt/sources.list.d/vscodium.list
		sudo apt update && sudo apt install codium -y
		success "done"
	fi

	# install nvm
	prompt "Install nvm ? (y/n) " answer_nvm
	answer_nvm=${answer_nvm,,}
	if [[ "$answer_nvm" =~ ^(yes|y)$ ]]; then
		info "installing nvm"
		wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
		success "done"
	fi

	# installing oh-my-zsh
	prompt "Install oh-my-zsh ? (y/n) " answer_omz
	answer_omz=${answer_omz,,}
	if [[ "$answer_omz" =~ "^(yes|y)$" ]]; then
		info "install oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -unattended
		success "done"

		info "installing font for zsh theme"
		sudo apt install fonts-powerline
		success "done"
	fi

	# installing zsh-autosuggestions
	prompt "Install zsh-autossuggestions ? (y/n) " answer_autosugg
	answer_autosugg=${answer_autosugg}
	if [[ "$answer_autosugg" =~ ^(yes|y)$ ]]; then
		info "install zsh-autossuggestions"
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
		success "done"
	fi

	# install discord
	prompt "Install discord ? (y/n) " answer_discord
	answer_discord=${answer_discord,,}
	if [[ "$answer_discord" =~ ^(yes|y)$ ]]; then
		info "installing discord"
		TEMP_DEB="$(mktemp)"
		wget -O "$TEMP_DEB" 'https://discord.com/api/download?platform=linux&format=deb' | sudo dpkg -i "$TEMP_DEB"
		rm -rf "$TEMP_DEB"
		success "done"
	fi

	symlinker
fi

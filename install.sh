#/usr/env bash

echo "alias dgit='git --git-dir ~/.dotfiles/.git --work-tree=\$HOME'"

sudo apt update && sudo apt upgrade

sudo apt install curl

# install vscodium
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg

# installing zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

sudo apt install fonts-powerline

# install discord
TEMP_DEB="$(mktemp)"
wget -O "$TEMP_DEB" 'https://discord.com/api/download?platform=linux&format=deb'sudo dpkg -i "$TEMP_DEB"
rm -rf "$TEMP_DEB"

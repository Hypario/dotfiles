#!/usr/bin/env bash

info() {
  printf "\r\n [ \033[00;34m..\033[0m ] $1\r\n"
}

user() {
  printf "\r\n [ \033[0;33m?\033[0m ] $1"
}

success() {
  printf "\r\033[2K [ \033[00;32mOK\033[0m ] $1\n"
}

fail() {
  printf "\r\033[2K [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit $?
}

prompt() {
  printf "\r\n [ \033[00;34m?\033[0m ] $1"
  read $2
}

symlinker() {
  info 'Symlinking dotfiles'

  local overwrite=true overwrite_all=true backup_all=false skip_all=false

  for file in $(find -H "$HOME/dotfiles" -maxdepth 3 -name '*.symlink'); do
    local dest="$HOME/.$(basename "${file%.*}")"

    ln -sf "$file" "$dest"
    success "linked $file to $dest"
  done
  
  success "done"
}

checkUpdate() {
	cd $HOME/dotfiles > /dev/null
	
	REMOTE=$(git ls-remote origin master | cut -f1)
	LOCAL=$(git rev-parse HEAD)

	cd - > /dev/null
	if [ $LOCAL = $REMOTE ]; then
		return -1;
	else
		return 0;
	fi
}

updateDotfiles() {
	checkUpdate
	if [ $? -eq 0 ]; then
		prompt "Update detected for your dotfiles, do you wanna update ? (y/n) " choice
		choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
		if [[ "$choice" =~ ^(yes|y)$ ]]; then
			cd $HOME/dotfiles > /dev/null
			git pull
			cd - > /dev/null
		fi
	fi
}

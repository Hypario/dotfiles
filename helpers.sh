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
	if ( checkInternet ) && checkUpdate; then
		prompt "Update detected for your dotfiles, do you wanna update ? (y/n) " choice
		choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
		if [[ "$choice" =~ ^(yes|y)$ ]]; then
			cd $HOME/dotfiles > /dev/null
			git pull
			cd - > /dev/null
			symlinker
		fi
	fi
}

checkInternet() {
	# stackoverflow https://stackoverflow.com/questions/929368/how-to-test-an-internet-connection-with-bash

	declare -a test_urls=("https://www.google.com/", "https://www.microsoft.com/", "https://www.cloudflare.com/")

	if [[ -f $HOME/dotfiles/.update.lock && -s $HOME/dotfiles/.update.lock ]]; then
		typeset -i epoch=$(cat $HOME/dotfiles/.update.lock)
		now=$(date +%s)
		if [ $(expr $epoch - $now) -lt 0 ]; then
			rm $HOME/dotfiles/.update.lock
		else
			return 1
		fi
	else
		echo $(date -d "today 23:59:59" +%s) > $HOME/dotfiles/.update.lock
	fi

	info "testing internet connection to check if dotfiles updates are needed"

	processes="0"
	pids=()

	for test_url in ${test_urls[@]}; do
		curl --silent --head $test_url > /dev/null &
		pids+="$!"
		processes=$(($processes + 1))
	done

	while [ $processes -gt 0 ]; do
		for pid in $pids; do
			if ! ps | grep "$pid" > /dev/null; then
				# Process no longer running
				processes=$(($processes - 1))
				pids=( "${pids[@]/$pid}" )

				if wait $pid; then
					# Success! We have a connection to at least one public site, so the
					# internet is up. Ignore other exit statuses.
					kill -TERM $pids > /dev/null 2>&1 || true
					return 0
				fi
			fi
		done
		# wait -n $pids # Better than sleep, but not supported on all systems
		sleep 0.1
	done

	info "No internet found"

	if [ ! -s $HOME/dotfiles ]; then
		target=$(date )
	fi
	return 1
}

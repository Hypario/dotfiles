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

error() {
  printf "\r\033[2K [\033[0;31mFAIL\033[0m] $1\n"
}

fail() {
  error $1
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

  for file in $(find -H "$HOME/dotfiles" -maxdepth 5 -name '*.symlink'); do
    local rel="${file#$HOME/dotfiles/}"
    local dest
    if [[ "$rel" == */* ]]; then
      # nested: mirror the folder structure under $HOME (e.g. docker/config.json.symlink -> ~/.docker/config.json)
      dest="$HOME/.$(dirname "$rel")/$(basename "${file%.*}")"
    else
      dest="$HOME/.$(basename "${file%.*}")"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$file" "$dest"
    success "linked $file to $dest"
  done
  
  success "done"
}

daily_lock() {
  local lock="$HOME/.cache/dotfiles/$1.lock"
    if [[ -s "$lock" ]]; then
      typeset -i epoch=$(cat "$lock")
      if [ $(($epoch - $(date +%s))) -gt 0 ]; then
        return 1
      fi
    fi
    mkdir -p "$(dirname "$lock")"
    echo $(date -d "today 23:59:59" +%s) > "$lock"
    return 0
}

checkUpdate() {
	cd $HOME/dotfiles > /dev/null
	
	REMOTE=$(git ls-remote origin master | cut -f1)
	LOCAL=$(git rev-parse HEAD)

	cd - > /dev/null
	if [ $LOCAL = $REMOTE ]; then
		return 1;
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

  daily_lock update || return 1

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

	return 1
}

bw() {
  # certificate used for bitwarden cli to avoid SSL errors
  NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt command bw "$@"
}

bw_ensure_unlock() {
  # Stage 1: try the keyring cache
  if [ -z "$BW_SESSION" ]; then
    export BW_SESSION="$(keyctl pipe %user:bw_session 2>/dev/null)"
  fi

  # Stage 2: cache miss → unlock interactively and store it
  if ! bw status --session "$BW_SESSION" 2>/dev/null | grep -q '"status":"unlocked"'; then
    info "unlocking bitwarden vault" >&2
    export BW_SESSION="$(bw unlock --raw)" || return 1
    echo -n "$BW_SESSION" | keyctl padd user bw_session @u > /dev/null
  fi
}

bw_get_password() {
  local value
  info "fetching password of '$1' from bitwarden" >&2
  value=$(bw get password "$1" --session "$BW_SESSION") || { error "Password for item '$1' not found" >&2; return 1; }
  echo "$value"
}

bw_get_username() {
  local value
  info "fetching username of '$1' from bitwarden" >&2
  value=$(bw get username "$1" --session "$BW_SESSION") || { error "Username for item '$1' not found" >&2; return 1; }
  echo "$value"
}

bw_get_uri() {
  local value
  info "fetching uri of '$1' from bitwarden" >&2
  value=$(bw get uri "$1" --session "$BW_SESSION") || { error "URI for item '$1' not found" >&2; return 1; }
  echo "$value"
}

bw_secret() {
  local key="secret_$1"
  local value="$(keyctl pipe %user:$key 2>/dev/null)"

  if [ -z "$value" ]; then
    # cache miss -> we need to fetch the secret from bitwarden
    bw_ensure_unlock
    syncBitwardenVault
    value=$(bw_get_password "$1") || return 1
    echo -n "$value" | keyctl padd user "$key" @u > /dev/null
  fi

  echo "$value"
}

dockerLogin() {
  local registry=""
  local item="JFrog_work_token"
  local OPTIND opt
  while getopts ":r:i:h" opt; do
    case "$opt" in
      r) registry="$OPTARG" ;;
      i) item="$OPTARG" ;;
      h)
        echo "usage: dockerLogin [-r registry] [-i bitwarden item]" >&2
        echo "  -r  registry to log into (default: URI field of the bitwarden item)" >&2
        echo "  -i  bitwarden item holding the credentials (default: JFrog_work_token)" >&2
        return 0 ;;
      :) error "option -$OPTARG requires an argument" >&2; return 1 ;;
      \?) error "unknown option -$OPTARG" >&2; return 1 ;;
    esac
  done
  bw_ensure_unlock
  local user
  if [ -z "$registry" ]; then
    registry="$(bw_get_uri "$item")" || return 1
  fi
  user="$(bw_get_username "$item")" || return 1
  [ -n "$registry" ] || { error "no registry for '$item': pass one as argument or set the URI field in the bitwarden item" >&2; return 1; }
  [ -n "$user" ] || { error "no username found in bitwarden item '$item'" >&2; return 1; }
  bw_secret "$item" | docker login "$registry" -u "$user" --password-stdin
}

bw_cache_clear() {
  local id
  for id in $(keyctl rlist @u 2>/dev/null); do
    if keyctl describe "$id" 2>/dev/null | grep -q "secret_"; then
      keyctl unlink "$id" @u 2>/dev/null
    fi
  done
}

syncBitwardenVault() {
  if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    rm -f "$HOME/.cache/dotfiles/bw_sync.lock"
  fi
  daily_lock bw_sync || return 1
  bw_ensure_unlock
  info "Syncing bitwarden vault" >&2
  if bw sync --session "$BW_SESSION" > /dev/null 2>&1; then
    bw_cache_clear
    success "Bitwarden vault synced" >&2
  else
    error "Failed to sync Bitwarden vault, using local cache" >&2
  fi
}

resetBw() {
  bw_cache_clear
  keyctl unlink %user:bw_session @u 2>/dev/null
  unset BW_SESSION
  success "bitwarden cache and session cleared" >&2
}


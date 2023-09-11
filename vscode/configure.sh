#!/bin/sh

source helpers.sh

info "Installing VScode's keybindings and settings"

ln -sf "$(pwd)/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
success "linked $(pwd)/vscode/keybindings.json to $HOME/.config/Code/User/keybindings.json"

ln -sf "$(pwd)/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
success "linked $(pwd)/vscode/settings.json to $HOME/.config/Code/User/settings.json"

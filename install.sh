#!/bin/bash
DOTVERSE=~/.dotverse

[ -f ~/.zshrc ] && rm ~/.zshrc
[ -f ~/.tmux.conf ] && rm ~/.tmux.conf
[ -f ~/.wezterm.lua ] && rm ~/.wezterm.lua

ln -sf $DOTVERSE/zsh/.zshrc ~/.zshrc
ln -sf $DOTVERSE/tmux/.tmux.conf ~/.tmux.conf
ln -sf $DOTVERSE/wezterm/.wezterm.lua ~/.wezterm.lua

echo "Symlinks created successfully!"

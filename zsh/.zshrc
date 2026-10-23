export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="avit"

plugins=(
  git
  tmux
  docker
  docker-compose
  zsh-autosuggestions
  kubectl
)

ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# ############## ALIAS ##############
alias python="python3"
alias pip="pip3"
alias lzg="lazygit"
alias vi="nvim"

# special for brew
alias brew='sudo -Hu $(whoami) brew'

# ############## EXPORTS ##############
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.pyenv/shims:$PATH"

# readline
export LDFLAGS="-L/opt/homebrew/opt/readline/lib"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/readline/lib/pkgconfig"

# sqlite
export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/sqlite/lib"
export CPPFLAGS="-I/opt/homebrew/opt/sqlite/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/sqlite/lib/pkgconfig"

# Android Studio
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# ############## COMMANDS ##############
# Docker
fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# Ngrok
if command -v ngrok &>/dev/null; then
	eval "$(ngrok completion)"
fi

# mise
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="avit"

plugins=(
  git
  tmux
  docker
  docker-compose
  zsh-autosuggestions
)

ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# ############## ALIAS ##############
alias python="python3"
alias pip="pip3"
alias lzd="lazydocker"
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

# nvm
export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# go
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

# ############## CUSTOM FUNCTIONS ##############
# Ngrok
if command -v ngrok &>/dev/null; then
	eval "$(ngrok completion)"
fi

# Docker
fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# Android Studio
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools


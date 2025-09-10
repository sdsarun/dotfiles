export ZSH="$HOME/.ohmyzsh"
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
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# go
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

# sdkman THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ############## CUSTOM FUNCTIONS ##############
# Ngrok
if command -v ngrok &>/dev/null; then
	eval "$(ngrok completion)"
fi

# Docker
fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit
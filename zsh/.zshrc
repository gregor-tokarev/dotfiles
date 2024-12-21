export PATH=/opt/homebrew/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completio

alias lg='lazygit'
alias ld='lazydocker'
# source ./aliases.sh
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Load Angular CLI autocompletion.
source <(ng completion script)

export DVM_DIR="/Users/gregortokarev/.dvm"
export PATH="$DVM_DIR/bin:$PATH"

# Created by ThEeLxD192

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zsh configuration

# Historial
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Optimization settings
setopt APPEND_HISTORY 
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE

# Alias

# Bat alias (Better cat)
alias cat='bat --style=plain'
alias catt='bat --style=numbers,changes'

# EZA alias (Better ls)
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias tree='eza --tree --icons'

#ingresapp-api-db aliases
alias ing-db-export='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-db bash_scripts/db_scripts/export-db.sh'
alias ing-db-import='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-db bash_scripts/db_scripts/import-db.sh'
alias ing-db-cloud-sql-import='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-db bash_scripts/db_scripts/import-db-from-cloud-sql-dump.sh'

#ingresapp-api aliases
alias ing-api-install='~/Ingresapp/ingresapp-api/bash_scripts/install.sh'
alias ing-api-run-test='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/run-test.sh'
alias ing-api-make-migrations='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/make-migrations.sh'
alias ing-api-migrate='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/migrate.sh'
alias ing-api-start-feature='~/Ingresapp/ingresapp-api/bash_scripts/start-new-feature.sh'
alias ing-api-format='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/run-black.sh'
alias ing-api-lint='~/Ingresapp/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/linting-changes.sh'

#ingresapp google cloud cli aliases
alias ing-gcloud-auth='~/Ingresapp/ingresapp-api/bash_scripts/gcloud_scripts/auhtenticate.sh'
alias ing-gcloud-get-production-db-dump='~/Ingresapp/ingresapp-api/bash_scripts/gcloud_scripts/get-production-db-dump.sh'

#ingresapp-core aliases
alias ing-core-install='~/Ingresapp/ingresapp-core/docker-executer.sh ingresapp-core bash_scripts/install-dev-dependencies.sh'
alias ing-core-run-tests='~/Ingresapp/ingresapp-core/docker-executer.sh ingresapp-core bash_scripts/run-tests.sh'
alias ing-core-format='~/Ingresapp/ingresapp-core/docker-executer.sh ingresapp-core bash_scripts/run-black.sh'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/ThEeLxD192/Downloads/google-cloud-cli/google-cloud-sdk/path.zsh.inc' ]; then . '/home/ThEeLxD192/Downloads/google-cloud-cli/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/ThEeLxD192/Downloads/google-cloud-cli/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/ThEeLxD192/Downloads/google-cloud-cli/google-cloud-sdk/completion.zsh.inc'; fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# PowerLevel10k location
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# Plugins

# A better cd
eval "$(zoxide init zsh)"

# A better search for zsh
source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh

# Syntax Highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Syntax Autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Functions

# Extract a file in this current location.
ex () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "❌ '$1' This cannot be extract with ex()" ;;
    esac
  else
    echo "❌ '$1' this file is not a valid format."
  fi
}

# Extract a file in a specific directory
exd () {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Use: exd <file> <directory>"
        return 1
    fi

    if [ ! -f "$1" ]; then
        echo "❌ This file '$1' doesn't exist."
        return 1
    fi

    # Create this directory if it's doesn't exist.
    if [ ! -d "$2" ]; then
        mkdir -p "$2"
        echo "📂 Directory '$2' createad."
    fi

    echo "extracting $1 to $2..."

    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" -C "$2" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" -C "$2" ;;
        *.tar)            tar xf "$1" -C "$2"  ;;
        *.rar)            unrar x "$1" "$2"    ;;
        *.zip)            unzip "$1" -d "$2"   ;;
        *.7z)             7z x "$1" -o"$2"     ;;
        *)                echo "❌ This cannot be extract with exd() -> Invalid format." ;;
    esac
}

# Using micro
export EDITOR='micro'
export VISUAL='micro'
export "MICRO_TRUECOLOR=1"


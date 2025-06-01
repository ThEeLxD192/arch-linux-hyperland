# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

alias cat='bat'

# pnpm
export PNPM_HOME="/home/ThEeLxD192/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="$HOME/.cargo/bin:$PATH"

#ingresapp-api-db aliases
alias ing-db-export='~/Documents/ingresapp-api/docker-executer.sh ingresapp-db bash_scripts/db_scripts/export-db.sh'
alias ing-db-import='~/Documents/ingresapp-api/docker-executer.sh ingresapp-db bash_scripts/db_scripts/import-db.sh'
alias ing-db-cloud-sql-import='~/Documents/ingresapp-api/docker-executer.sh ingresapp-db bash_scripts/db_scripts/import-db-from-cloud-sql-dump.sh'

#ingresapp-api aliases
alias ing-api-install='~/Documents/ingresapp-api/bash_scripts/install.sh'
alias ing-api-run-test='~/Documents/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/run-test.sh'
alias ing-api-make-migrations='~/Documents/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/make-migrations.sh'
alias ing-api-migrate='~/Documents/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/migrate.sh'
alias ing-api-start-feature='~/Documents/ingresapp-api/bash_scripts/start-new-feature.sh'
alias ing-api-format='~/Documents/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/run-black.sh'
alias ing-api-lint='~/Documents/ingresapp-api/docker-executer.sh ingresapp-api bash_scripts/linting-changes.sh'

#ingresapp google cloud cli aliases
alias ing-gcloud-auth='~/Documents/ingresapp-api/bash_scripts/gcloud_scripts/auhtenticate.sh'
alias ing-gcloud-get-production-db-dump='~/Documents/ingresapp-api/bash_scripts/gcloud_scripts/get-production-db-dump.sh'

#ingresapp-core aliases
alias ing-core-install='~/Documents/ingresapp-core/docker-executer.sh ingresapp-core bash_scripts/install-dev-dependencies.sh'
alias ing-core-run-tests='~/Documents/ingresapp-core/docker-executer.sh ingresapp-core bash_scripts/run-tests.sh'
alias ing-core-format='~/Documents/ingresapp-core/docker-executer.sh ingresapp-core bash_scripts/run-black.sh'

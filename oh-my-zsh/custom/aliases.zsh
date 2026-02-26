alias c="clear"
alias vim="nvim"

alias sites="cd ~/Herd"
alias carjudge="cd ~/Herd/carjudge"

alias nf="rm -rf node_modules/ package-lock.json && npm install"
alias ni="npm install"
alias nu="npm update"
alias nd="npm run dev"
alias nb="npm run build"

alias cf="rm -rf vendor/ composer.lock && composer i"

alias a="artisan"
alias am="artisan migrate"
alias amf="artisan migrate:fresh"
alias amfs="artisan migrate:fresh --seed"
alias wipe="artisan db:wipe"
alias seed="artisan db:seed"
alias tinker="artisan tinker"
alias serve="artisan serve"
alias test="artisan test"

alias phpunit="vendor/bin/phpunit"
alias pest="vendor/bin/pest"
alias phpstan="vendor/bin/phpstan analyse --memory-limit=2G"
alias insight="php artisan insight"
alias patrol="vendor/bin/patrol"
alias pint="vendor/bin/pint --parallel"
alias rector="vendor/bin/rector"

alias p="rector && pint && pest --arch && phpstan"
alias ship="./ship"
alias pr="./pr"
alias fix="./fix"

comme () {
        git add --all
        if (($# > 1))
        then
                params=''
                for i in $*
                do
                        params=" $params $i"
                done
                git commit -m "$params"
        else
                git commit -m "$1"
        fi
}

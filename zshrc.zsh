export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
DISABLE_UPDATE_PROMPT="true"
export AWS_PROFILE="default"
export UPDATE_ZSH_DAYS=7
if [ -f ~/.certs/SystemRootCertificates.pem ] ; then
    export NODE_EXTRA_CA_CERTS="$HOME/.certs/SystemRootCertificates.pem"
fi
plugins=(git)
source $ZSH/oh-my-zsh.sh

set -o vi

export EDITOR='vim'

export LESSOPEN="| src-hilite-lesspipe.sh %s"
export LESS=' -R'

## PATH setup
# Base system paths
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Homebrew (chip architecture, not macOS version)
if [[ $(uname -m) == "arm64" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# Java (Homebrew OpenJDK)
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# User bins
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Deduplicate PATH
path=("${(@u)path}")

## Aliases
alias apwhois="whois -h whois.apnic.net"
alias awhois="whois -h whois.arin.net"
alias c="curl -sq"
alias cg="cd ~/git"
alias claudia="claude"
alias diff="colordiff"
alias h="history | grep "
alias k="kubectl"
alias kd="kubectl config use-context dev"
alias kp="kubectl config use-context prod"
alias mkd=mkdir
alias opera="/Applications/Opera.app/Contents/MacOS/Opera"
alias rgr='grep -r'  # rg is reserved for ripgrep
alias rmt="find . -name .terraform -type d -exec rm -rf {} \;"
alias rwhois="whois -h whois.ripe.net"
alias s="ssh -q"
alias tfa="terraform apply"
alias tfd="terraform destroy"
alias tff="terraform fmt"
alias tfi="terraform init"
alias tfp="terraform plan"
alias v="vim"
alias vax="find . \( -name '*.yaml' -o -name '*.json' -o -name '*.txt' -o -name '*.log' \) -print0 | xargs -0 xattr -d com.apple.quarantine 2>/dev/null"
alias vz="vim ~/.zshrc && source ~/.zshrc"
alias z="source ~/.zshrc"
alias zc="source ~/.zshconfig/*.zsh"

## Functions

function fm() {
    ffmpeg -hide_banner -loglevel error -i "$@" -f ffmetadata -
}

# Prevent pushes to main/master
function _git_guard_main() {
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        echo "Refusing to push to '$branch'. Use a feature branch instead."
        return 1
    fi
}

function git_safe_push() {
    _git_guard_main || return 1
    command git push "$@"
}

function git_safe_push_upstream() {
    _git_guard_main || return 1
    command git push --set-upstream origin "$(git symbolic-ref --short HEAD)"
}

alias gp='git_safe_push'
alias gpsup='git_safe_push_upstream'

function gres() {
    gco main 2>/dev/null || gco master
    gl
}

function prune() {
    local delete_arg="-d"

    while getopts "f" opt; do
        case $opt in
            f) delete_arg="-D" ;;
        esac
    done

    git fetch -p

    # `git branch -vv` marks the checked-out branch with a leading "* " instead of
    # two spaces, which shifts $1 to the literal "*" for that line — strip it first.
    local local_stale_branches=("${(@f)$(git branch -vv | awk '/origin\/.*: gone]/ {sub(/^\* /, ""); print $1}')}")

    if [[ -z "$local_stale_branches" ]]; then
        echo "No stale branches to delete."
        return
    fi

    # git refuses to delete the branch you're on — hop to the default branch first
    # if it's one of the stale ones.
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if (( ${local_stale_branches[(Ie)$current_branch]} )); then
        local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
        default_branch="${default_branch:-main}"
        echo "Current branch '$current_branch' is stale — switching to '$default_branch' first."
        git checkout "$default_branch"
    fi

    echo "Deleting stale branches:"
    for branch in $local_stale_branches; do
        echo "  $branch"
        git branch "$delete_arg" "$branch"
    done
}

function ssm() {
    aws ssm start-session --target "$@"
}

## zi plugin manager
if [[ ! -f $HOME/.zi/bin/zi.zsh ]]; then
    print -P "%F{33}▓▒░ %F{160}Installing (%F{33}z-shell/zi%F{160})…%f"
    command mkdir -p "$HOME/.zi" && command chmod go-rwX "$HOME/.zi"
    command git clone -q --depth=1 --branch "main" https://github.com/z-shell/zi "$HOME/.zi/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi
source "$HOME/.zi/bin/zi.zsh"
autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi
zicompinit

## Local config overrides
if [ -d $HOME/.zshconfig ]; then
    for f in $HOME/.zshconfig/*.zsh; do
        source $f
    done
fi
[[ $- == *i* ]] && clear

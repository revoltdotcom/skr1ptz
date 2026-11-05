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

# History: oh-my-zsh defaults to 50000/10000; keep a large finite cap.
# share_history (set by oh-my-zsh) already writes incrementally, so no inc_append_history.
HISTSIZE=250000
SAVEHIST=250000
setopt EXTENDED_HISTORY       # timestamps
setopt HIST_IGNORE_SPACE      # leading space = not recorded (use for secrets)
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicates
setopt HIST_REDUCE_BLANKS

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
alias kgp="kubectl get pod"
alias kdp="kubectl describe pod"
alias kgd="kubectl get deployment"
alias klo="kubectl logs"
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
    local override="$1"
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ "$override" != true && ( "$branch" == "main" || "$branch" == "master" ) ]]; then
        echo "Refusing to push to '$branch'. Use a feature branch instead."
        echo "Override with: ${funcstack[2]} -F"
        return 1
    fi
}

# Pass -F as the first argument to allow pushing to main/master
function git_safe_push() {
    local override=false
    if [[ "$1" == "-F" ]]; then override=true; shift; fi
    _git_guard_main "$override" || return 1
    command git push "$@"
}

function git_safe_push_upstream() {
    local override=false
    if [[ "$1" == "-F" ]]; then override=true; shift; fi
    _git_guard_main "$override" || return 1
    command git push --set-upstream origin "$(git symbolic-ref --short HEAD)"
}

alias gp='git_safe_push'
alias gpsup='git_safe_push_upstream'

function gres() {
    gco main 2>/dev/null || gco master
    gl
}

function klp() {
    kubectl logs ${@} -p
}

function prune() {
    local delete_arg="-d"

    while getopts "f" opt; do
        case $opt in
            f) delete_arg="-D" ;;
        esac
    done

    git fetch -p

    # Use for-each-ref rather than parsing `git branch -vv`: the latter prefixes
    # branches with markers ("* " for current, "+ " for checked out in another
    # worktree) that shift the columns and get mistaken for branch names.
    local local_stale_branches=("${(@f)$(git for-each-ref --format='%(refname:short) %(upstream:remotename) %(upstream:track)' refs/heads | awk '$2 == "origin" && $3 == "[gone]" {print $1}')}")

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

    # Branches checked out in another worktree can't be deleted (even with -D);
    # skip them with a hint instead of letting git error out.
    local worktree_branches=("${(@f)$(git worktree list --porcelain | sed -n 's@^branch refs/heads/@@p')}")

    echo "Deleting stale branches:"
    for branch in $local_stale_branches; do
        if (( ${worktree_branches[(Ie)$branch]} )); then
            echo "  $branch (skipped: checked out in a worktree — 'git worktree remove' it first)"
            continue
        fi
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

export UV_NATIVE_TLS=1 # ADDED BY IRU
export UV_SYSTEM_CERTS=1 # ADDED BY IRU

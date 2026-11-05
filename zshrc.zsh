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

# Syntax highlighting in less, if source-highlight is installed (brew install source-highlight).
# Checked after PATH is built; with the helper missing, every less call prints "command not found".
if (( $+commands[src-hilite-lesspipe.sh] )); then
    export LESSOPEN="| src-hilite-lesspipe.sh %s"
fi

## Aliases
alias apwhois="whois -h whois.apnic.net"
alias awhois="whois -h whois.arin.net"
alias c="curl -qs"  # -q must come first, or curl still reads ~/.curlrc
alias cg="cd ~/git"
alias claudia="claude"
(( $+commands[colordiff] )) && alias diff="colordiff"
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
alias rmt="find . -name .terraform -type d -prune -exec rm -rf {} +"
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
# `source` reads one file (extra args become $1, $2, ...), so loop to reload every file.
alias zc='for _f in $HOME/.zshconfig/*.zsh(N); do source "$_f"; done; unset _f'

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
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -z "$branch" ]]; then
        echo "Not on a branch (detached HEAD); nothing to set upstream for."
        return 1
    fi
    command git push --set-upstream "$@" origin "$branch"
}

alias gp='git_safe_push'
alias gpsup='git_safe_push_upstream'

# Check out the default branch and pull. git_main_branch comes from the oh-my-zsh git plugin.
function gres() {
    git checkout "$(git_main_branch)" && git pull
}

function klp() {
    kubectl logs "$@" -p
}

# Delete local branches whose upstream is gone. -f force-deletes unmerged ones.
function prune() {
    local delete_arg="-d" opt branch

    while getopts "f" opt; do
        case $opt in
            f) delete_arg="-D" ;;
            *) echo "Usage: prune [-f]"; return 1 ;;
        esac
    done

    git fetch -p || return 1

    # %(upstream:track) is "[gone]" once the remote branch is deleted. Unlike parsing
    # `git branch -vv`, this is not tripped up by the "*"/"+" markers or commit subjects.
    local stale_branches=(${(f)"$(git for-each-ref refs/heads \
        --format='%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)')"})

    if (( ! ${#stale_branches} )); then
        echo "No stale branches to delete."
        return
    fi

    # git refuses to delete the checked-out branch, so switch off it first.
    local current_branch=$(git branch --show-current)
    if (( ${stale_branches[(Ie)$current_branch]} )); then
        local default_branch=$(git_main_branch)
        echo "Current branch '$current_branch' is stale — switching to '$default_branch' first."
        git checkout "$default_branch" || return 1
    fi

    echo "Deleting stale branches:"
    for branch in $stale_branches; do
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
# Sourced at top level, not inside a function, so `typeset` in these files stays global.
# (N) skips the loop instead of failing with "no matches found" when there are none.
for _f in $HOME/.zshconfig/*.zsh(N); do
    source "$_f"
done
unset _f
[[ $- == *i* ]] && clear

export UV_NATIVE_TLS=1 # ADDED BY IRU
export UV_SYSTEM_CERTS=1 # ADDED BY IRU

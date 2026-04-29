# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export BRAZIL_WORKSPACE_DEFAULT_LAYOUT=short

export AUTO_TITLE_SCREENS="NO"

# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false
export AWS_EC2_METADATA_DISABLED=true

export PROMPT="
%{$fg[white]%}(%D %*) <%?> [%~] $program %{$fg[default]%}
%{$fg[cyan]%}%m %#%{$fg[default]%} "

export RPROMPT=

set-title() {
    echo -e "\e]0;$*\007"
}

ssh() {
    set-title $*;
    /usr/bin/ssh -2 $*;
    set-title $HOST;
}

## Envs
for f in /apollo/env/*/bin; do
    [[ -d "$f" ]] && export PATH="$PATH:$f"
done

## Builders
alias e=emacs
alias bb=brazil-build

alias bba='brazil-build apollo-pkg'
alias bre='brazil-runtime-exec'
alias brc='brazil-recursive-cmd'
alias bws='brazil ws'
alias bwsuse='bws use -p'
alias bwscreate='bws create -n'
alias brc=brazil-recursive-cmd
alias bbr='brc brazil-build'
alias bball='brc --allPackages'
alias bbb='brc --allPackages brazil-build'
alias bbra='bbr apollo-pkg'

export PATH=$HOME/.toolbox/bin:$PATH
source ~/powerlevel10k/powerlevel10k.zsh-theme

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit ice depth=1
zinit light junegunn/fzf

# load key bindings + completion
zinit ice wait lucid
zinit light junegunn/fzf/shell
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
zle -N menu-search
zle -N recent-paths
### End of Zinit's installer chunk
## Zinit plugins
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zdharma-continuum/fast-syntax-highlighting
bindkey "˙" fzf-history-widget

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Move all my scripts
export PATH=$HOME/.local/bin/scripts:$PATH

export KITTY_SHELL_INTEGRATION=enabled
export KITTY_LISTEN_ON=ssh

# GetPackage
get_package () {
  cd ~/code && brazil ws create --name ${1} && cd ${1} && brazil ws use -p ${1}
}
autoload -Uz compinit && compinit

# Set up mise for runtime management
eval "$(/home/alainlam/.local/bin/mise activate zsh)"
source ~/.local/share/mise/completions.zsh
alias finch='sudo HOME=/home/alainlam DOCKER_CONFIG=/home/alainlam/.docker finch'

export PATH="$HOME/.local/bin:$PATH"
export MESHCLAW_PROJECT_DIR="/home/alainlam/.meshclaw-app"

# Added by AIM CLI
export PATH="/local/home/alainlam/.aim/mcp-servers:$PATH"

# MeshClaw
export PATH="/home/alainlam/code/MeshClaw/src/MeshClaw/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# TMUX
alias tmls="tmux list-session"
alias tma="tmux attach-session -t"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Personal
alias qc='source ~/scripts/create_date_folder.sh'
alias lh='/apollo/env/envImprovement/bin/expand-hostclass -r --hosts-only'
alias ddb="/apollo/bin/env -e MechanicBigBirdCli /apollo/env/MechanicBigBirdCli/bin/mechanic-cli"

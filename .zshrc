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

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

## zsh
#
export ZSH="$HOME/.oh-my-zsh"
plugins=(git fzf zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

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
# eval "$(/home/alainlam/.local/bin/mise activate zsh)"
# source ~/.local/share/mise/completions.zsh
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
alias qcn='source ~/scripts/create_date_folder.sh -n'
alias lh='/apollo/env/envImprovement/bin/expand-hostclass -r --hosts-only'
alias ddb="/apollo/bin/env -e MechanicBigBirdCli /apollo/env/MechanicBigBirdCli/bin/mechanic-cli"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

## Editor
export EDITOR='nvim'
export VISUAL='nvim'

export PATH=$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"

## DdbStorageApiOncallTools
source /apollo/env/DdbStorageApiOncallTools/lib/sim.sh
source /apollo/env/DdbStorageApiOncallTools/lib/checkhelp.sh
## KVPC
 function ssh2hc-kvpc() {
      hostclass=$1
      # Get a host from the hostclass to SSH to
      host=$(/apollo/env/envImprovement/bin/expand-hostclass --hosts-only --one-host $hostclass)
  
      # Figure out the region from the hostclass
      region=''
      temp=$hostclass
      while [[ $temp =~ '\b(\w{3})\b' ]]; do
          region=($(echo $match[1] | tr 'A-Z' 'a-z'))
  
          # Use RIP to check if the three letter combination is a valid region
          ripData=$(echo $(ripcli -r "$region" -a status))
          if [[ "$ripData" != "Region not found" ]]; then
              break
          fi  
          
          # Remove the match and look for next match
          temp=${temp#*$match[1]}
      done
      
      catalyst_bastion_host='catalyst-prod-bastion-'$region'.ec2.amazon.com'
      ssh -A -J $catalyst_bastion_host $host
  }

alias wiki="cd /home/alainlam/code/AlainlamWiki/src/AlainlamWiki/root"
alias ct="~/scripts/ct.sh"

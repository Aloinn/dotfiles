# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Host detection: cloud desktop vs local (mac) ---
# Cloud desktops are named dev-dsk-<user>-...; gate heavy/cloud-only setup on this.
if [[ "$(hostname)" == dev-dsk-* ]]; then
  IS_CLOUD_DESKTOP=true
else
  IS_CLOUD_DESKTOP=false
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

## Envs (cloud desktop only — /apollo doesn't exist on mac, and globbing it is slow)
if $IS_CLOUD_DESKTOP; then
  for f in /apollo/env/*/bin; do
      [[ -d "$f" ]] && export PATH="$PATH:$f"
  done
fi

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
export FZF_BASE=/path/to/fzf/install/dir
# linuxbrew — cloud desktop only (heavy eval; path doesn't exist on mac)
if $IS_CLOUD_DESKTOP; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

## zsh
#
export ZSH="$HOME/.oh-my-zsh"
plugins=(git fzf zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Move all my scripts
export PATH=$HOME/.local/bin/scripts:$PATH

export KITTY_SHELL_INTEGRATION=enabled
export KITTY_LISTEN_ON=ssh

# GetPackage - auto-resolves version set from master VS (assumes -1.0 major version)
get_package () {
  local pkg="${1}"
  local base_dir="${2:-$HOME/code}"
  local mv="${pkg}-1.0"

  # Resolve master version set (try 'live' VS first, then first consuming VS)
  local master_vs first_vs
  master_vs=$(brazil package print --package "${pkg}" --majorVersion "1.0" --versionSet live 2>&1 \
    | grep 'master vs:' | sed 's/.*master vs: //; s/ |.*//')

  if [[ -z "${master_vs}" ]]; then
    # Package not in live — grab first consuming VS and query master from there
    first_vs=$(brazil package listversionsets -mv "${mv}" --versionSetLimit 1 2>&1 | grep '/' | head -1)
    if [[ -n "${first_vs}" ]]; then
      master_vs=$(brazil package print --package "${pkg}" --majorVersion "1.0" --versionSet "${first_vs}" 2>&1 \
        | grep 'master vs:' | sed 's/.*master vs: //; s/ |.*//')
    fi
  fi

  if [[ -z "${master_vs}" ]]; then
    echo "⚠ Could not resolve master VS for ${mv}, trying ${pkg}/development..."
    master_vs="${pkg}/development"
  fi

  echo "📦 ${pkg} → VS: ${master_vs}"

  cd "${base_dir}" \
    && brazil ws create --name "${pkg}" --versionSet "${master_vs}" \
    && cd "${pkg}" \
    && brazil ws use -p "${pkg}"
}
refactor () {
  get_package "${1}" "$HOME/refactor"
}
get_package2 () {
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
if $IS_CLOUD_DESKTOP; then
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm (SLOW — cloud desktop only)
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

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

if $IS_CLOUD_DESKTOP; then
  export PATH=$HOME/.rbenv/bin:$PATH
  eval "$(rbenv init -)"
fi

## DdbStorageApiOncallTools (cloud desktop only — /apollo paths)
if $IS_CLOUD_DESKTOP; then
  source /apollo/env/DdbStorageApiOncallTools/lib/sim.sh
  source /apollo/env/DdbStorageApiOncallTools/lib/checkhelp.sh
fi
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

# Fixing FZF widgets
# # Unbind CTRL-T, CTRL-R, and ALT-C in Zsh
bindkey -r '^T'
bindkey -r '^R'
bindkey -r '\M-c'

bindkey "˙" fzf-history-widget
bindkey "^H" fzf-history-widget
bindkey "ƒ" fzf-cd-widget

tmux-smart-attach() {
    if [ -n "$TMUX" ]; then
        echo "Already inside a tmux session!"
    else
        # Attaches to an existing session, or creates a new one if none exist
        tmux attach-session -t base 2>/dev/null || tmux new-session -s base
    fi
}

bindkey -s "6;9u" '^Utmux-smart-attach^M'
unset GEM_HOME GEM_PATH RUBYOPT RUBYLIB

# GTAS RELATED

gtas() {
  cd /home/alainlam/code/BigBirdGTAdminService/src/BigBirdGTAdminService;
  GTACCOUNT=857771923872
  wf_creds=$(ada credentials print --account $GTACCOUNT --role Admin)
  wf_access_key=$(echo "$wf_creds" | jq -rc ."AccessKeyId")
  wf_secret_key=$(echo "$wf_creds" | jq -rc ."SecretAccessKey")
  wf_session_token=$(echo "$wf_creds" | jq -rc ."SessionToken")

  gtas_creds=$(ada credentials print --account 601134390254 --role GTASLocalServer)
  gtas_access_key=$(echo "$gtas_creds" | jq -rc ."AccessKeyId")
  gtas_secret_key=$(echo "$gtas_creds" | jq -rc ."SecretAccessKey")
  gtas_session_token=$(echo "$gtas_creds" | jq -rc ."SessionToken")

  export workflowAwsAccessKeyId=$wf_access_key
  export workflowAwsSecretAccessKey=$wf_secret_key
  export workflowAwsSessionToken=$wf_session_token

  export AWS_ACCESS_KEY_ID=$gtas_access_key
  export AWS_SECRET_ACCESS_KEY=$gtas_secret_key
  export AWS_SESSION_TOKEN=$gtas_session_token

  brazil-build server
}

# --- Worktree server launchers (GTAS/GMDS, IAD/DUB) ---
# Port map (JDWP / HTTP / HTTPS):
#   gtas_iad: 5051 / 8800 / 8801   (target: server)
#   gtas_dub: 5052 / 8880 / 8881   (target: server-dub)
#   gmds_iad: 5061 / 8000 / 8001   (target: server)
#   gmds_dub: 5062 / 8900 / 8901   (target: server-dub)

# Kill anything listening on the given TCP ports
_kill_ports() {
  local port pids
  for port in "$@"; do
    pids=$(lsof -ti tcp:"$port" 2>/dev/null)
    if [ -n "$pids" ]; then
      echo "killing listeners on :$port -> ${pids//$'\n'/ }"
      kill ${=pids} 2>/dev/null
      sleep 1
      pids=$(lsof -ti tcp:"$port" 2>/dev/null)
      [ -n "$pids" ] && kill -9 ${=pids} 2>/dev/null
    fi
  done
}

# GTAS creds: workflow account + GTASLocalServer (same as gtas())
_gtas_env() {
  local wf_creds gtas_creds
  wf_creds=$(ada credentials print --account 857771923872 --role Admin) || return 1
  export workflowAwsAccessKeyId=$(echo "$wf_creds" | jq -rc .AccessKeyId)
  export workflowAwsSecretAccessKey=$(echo "$wf_creds" | jq -rc .SecretAccessKey)
  export workflowAwsSessionToken=$(echo "$wf_creds" | jq -rc .SessionToken)

  gtas_creds=$(ada credentials print --account 601134390254 --role GTASLocalServer) || return 1
  export AWS_ACCESS_KEY_ID=$(echo "$gtas_creds" | jq -rc .AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo "$gtas_creds" | jq -rc .SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo "$gtas_creds" | jq -rc .SessionToken)
}

# GMDS creds: GTMD test account (per GMDS README)
_gmds_env() {
  local gmds_creds
  gmds_creds=$(ada credentials print --account 857771923872 --role Admin) || return 1
  export AWS_ACCESS_KEY_ID=$(echo "$gmds_creds" | jq -rc .AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo "$gmds_creds" | jq -rc .SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo "$gmds_creds" | jq -rc .SessionToken)
}

# GTAS DUB creds: GTASLocalServer in the eu-west-1 test account 210665712600
# (per GTAS README: DUB server needs base creds from the DUB account so the
# fleetWideStsCacheAccess assume-role works, plus Dub-suffixed workflow vars)
_gtas_dub_env() {
  local wf_creds dub_creds
  wf_creds=$(ada credentials print --account 857771923872 --role Admin) || return 1

  export workflowAwsAccessKeyIdDub=$(echo "$wf_creds" | jq -rc .AccessKeyId)
  export workflowAwsSecretAccessKeyDub=$(echo "$wf_creds" | jq -rc .SecretAccessKey)
  export workflowAwsSessionTokenDub=$(echo "$wf_creds" | jq -rc .SessionToken)

  dub_creds=$(ada credentials print --account 210665712600 --role GTASLocalServer) || return 1
  export AWS_ACCESS_KEY_ID=$(echo "$dub_creds" | jq -rc .AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo "$dub_creds" | jq -rc .SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo "$dub_creds" | jq -rc .SessionToken)

}

gtas_iad() {
  _kill_ports 5051 8800 8801
  cd /local/home/alainlam/code/BigBirdGTAdminService/worktrees/iad/src/BigBirdGTAdminService || return
  _gtas_env || return
  brazil-build server
}

gtas_dub() {
  _kill_ports 5052 8880 8881
  cd /local/home/alainlam/code/BigBirdGTAdminService/worktrees/dub/src/BigBirdGTAdminService || return
  _gtas_dub_env || return
  brazil-build server-dub
}

gmds_iad() {
  _kill_ports 5061 8000 8001
  cd /local/home/alainlam/code/BigBirdGlobalMetadataService/worktrees/iad/src/BigBirdGlobalMetadataService || return
  _gmds_env || return
  brazil-build server
}

gmds_dub() {
  _kill_ports 5062 8900 8901
  cd /local/home/alainlam/code/BigBirdGlobalMetadataService/worktrees/dub/src/BigBirdGlobalMetadataService || return
  _gmds_env || return
  brazil-build server-dub
}

edit() {
  cd ~/dotfiles/.config
  nvim
}

# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

if [ -z "$SHELL" ]; then
    export SHELL="/bin/bash"
fi

export TERM="xterm"

# You may uncomment the following lines if you want `ls' to be colorized
export LS_OPTIONS='--color=auto'
export LSCOLORS=GxFxCxDxBxegedabagaced
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
alias c='cat'

# Some more alias to avoid making mistakes:
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

prompt_command () {
    if [ $? -eq 0 ]; then # set an error string for the prompt, if applicable
        ERRPROMPT=" "
    else
        ERRPROMPT='->($?) '
    fi
    local TIME=`date +"%H:%M:%S"`
    local PWD=`pwd`
    local GREEN="\[\033[0;32m\]"
    local CYAN="\[\033[0;36m\]"
    local BCYAN="\[\033[1;36m\]"
    local BLUE="\[\033[0;34m\]"
    local GRAY="\[\033[0;37m\]"
    local DKGRAY="\[\033[1;30m\]"
    local WHITE="\[\033[1;37m\]"
    local RED="\[\033[0;31m\]"
    # return color to Terminal setting for text color
    local DEFAULT="\[\033[0;39m\]"
    export PS1="\n${CYAN}\u${DEFAULT}@${CYAN}\h ${DEFAULT}${TIME} ${RED}${PWD}\n${GREEN}${DEFAULT}$ "
}

PROMPT_COMMAND=prompt_command


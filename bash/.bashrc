#
# ~/.bashrc
#

# if not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# source bash_aliases if it exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export EDITOR=vim

alias please='eval "sudo $(fc -ln -1)"'

if command -v thefuck >/dev/null 2>&1; then
    eval "$(thefuck --alias)"
fi

# AWS completion if it exists
if [ -f /usr/bin/aws_completer ]; then
    complete -C '/usr/bin/aws_completer' aws
fi

function printer_admin() {
    ssh "$1" -T -L 3631:localhost:631
}

# add locally installed ruby gems to the path
PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"

source ~/.bash_functions
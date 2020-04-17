#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# custom
alias ll='ls -lAFGhv --time-style=+%m-%d --group-directories-first'
alias la='ls -lAFv --format=single-column --group-directories-first'
export PATH=$PATH:~/bin

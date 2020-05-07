# # ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

##########
# CUSTOM #
##########

# List files
alias ll='ls -lAFGhv --time-style=+%m-%d --group-directories-first'
alias l='ls -lAFv --format=single-column --group-directories-first'

# tree view
TDEPTH=2
FLIMIT=25
alias t="tree -dvL ${TDEPTH} --filelimit=${FLIMIT}"
alias tt="tree -davL ${TDEPTH} --filelimit=${FLIMIT}"
alias ta="tree -av"
for i in {1..9}
do
  alias t${i}="tree -dvL ${i} --filelimit=${FLIMIT}"
  alias tt${i}="tree -davL ${i} --filelimit=${FLIMIT}"
done

# Prettier listing of processes
alias p='ps ax -o pid,user,%cpu,%mem,vsz,rss,stat,bsdstart,times,args --forest'

# nnn
export NNN_BMS="d:~/Downloads\
;h:~
;r:/
;c:~/code
;p:~/code/projects
;t:~/code/projects/dippa"
export NNN_USE_EDITOR=1

export PATH=~/bin:$PATH

# git autocomplete
. /usr/share/git/completion/git-completion.bash
# show git branch in PS1
. /usr/share/git/completion/git-prompt.sh
export PS1='\[\e[0;02m\]\W\[\e[m\]$(__git_ps1 " (%s)")$ '

_themes_completion() {
  COMPREPLY+=($(ls -lAv --format=single-column ~/.config/termite/themes))
}
complete -F _themes_completion theme

alias d='. gotodir'

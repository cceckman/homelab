#! /bin/sh
#
# Portable shell config- to local or remote hosts.

set -o vi
export EDITOR=vim

export PS1="\$(printf '∴ %i %s@%s:%s\n∵ ' \$? \$USER \$(hostname) \$PWD)"
export CLICOLOR="Yes"

## Common aliases
alias cl='clear; pwd; ls'
alias la='ls -lah'
# Don't reach over for -
alias lesss="less -S"
alias md="mkdir"
alias g="git"
alias mtr="mtr --curses"
alias z="exec zsh"

if ls -v >/dev/null 2>&1
then
  LSARGS="$LSARGS -v"
fi
if ls --color=auto >/dev/null 2>&1
then
  LSARGS="$LSARGS --color=auto"
fi
alias ls="ls $LSARGS"

mdcd() {
  # Make a directory, and move to it.
  mkdir -p $1 && cd $1
}

s() {
  # ls or cat? Now you don't have to choose!
  for arg in "$@"
  do
    if test -d "$arg"
    then
      ls "$arg"
    else
      cat "$arg"
    fi
  done
}

e() {
  # Invoke the "current" editor
  if test "$TERM_PROGRAM" = "vscode"
  then
    code "$@"
  else
    vim "$@"
  fi
}

ca() {
  git commit -a -m "$@"
}

title() {
  # change the title of the current window or tab.
  # Default:
  if test "$#" -eq 0
  then
    title "$USER"@"$(hostname)"
    return
  fi

  # Use the XTerm code: https://tldp.org/HOWTO/Xterm-Title-3.html
  # but it seems to work for other graphical terminals as well.
  # Octally-encoded: <ESC>]0;<title><BELL>
  echo -ne "\033]0;$*\007"
}
# Set title to user-at-host when starting a new shell.
title "$USER"@"$(hostname)"

# Keep this early, so subsequent includes can access SYSCOLOR.
if test -x $HOME/scripts/syscolor
then
  export SYSCOLOR="$($HOME/scripts/syscolor)"
else
  export SYSCOLOR="red"
fi

attach () {
  fixssh
  title "$1"
  tmux -u2 new-session -DA -s $1
  # Reset the title after exiting.
  title
}

# Load additional, optional posix-compatible stuff
if test -e "$HOME"/rcfiles/rc.sh
then
  . "$HOME"/rcfiles/rc.sh
fi

# Load additional, work-specific stuff
if test -e $HOME/rcfiles/work.rc.sh
then
  . $HOME/rcfiles/work.rc.sh
fi

# Jump to the next rcfile, if deployed
case "$SHELL" in
  */zsh)
    if test -e "$HOME"/rcfiles/rc.zsh
    then
      . "$HOME"/rcfiles/rc.zsh
    fi
    ;;
esac

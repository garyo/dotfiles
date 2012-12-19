# .bashrc for Gary Oberbrunner, 2012

# This is executed directly by bash if interactive and non-login,
# otherwise I source this from .profile or .zshrc/.kshrc
# (but only for interactive shells -- this should not be run for noninteractive shells)


# set for debugging:
# set -v
# set -x
# echo "Running .bashrc"
# echo "Incoming PATH:"
# echo $path | tr ':' '\n'

case `uname -s` in
  CYGWIN*) OS=windows ;;
  Darwin)  OS=mac ;;
  *)       OS=linux ;;
esac

########################################################################
# Misc stuff
umask 2

########################################################################
# PATH setup

path_append ()  { path_remove "$1"; export PATH="$PATH:$1"; }
path_prepend () { path_remove "$1"; export PATH="$1:$PATH"; }
path_remove ()  {
    # this way with awk and set is slow; use the pure bash version below.
    # newpath=`echo -n $PATH | gawk -v RS=: -v ORS=: -- '$0 != "'$1'"' | sed 's/:$//'`;
    # export PATH="$newpath"
    REMOVE="$1"
    PATH=$(IFS=':';t=($PATH);unset IFS;t=(${t[@]%%$REMOVE});IFS=':';echo "${t[*]}");
}

setpath_noise() {
    VC10="/Program Files (x86)/Microsoft Visual Studio 10.0/VC"
    VS10="/Program Files (x86)/Microsoft Visual Studio 10.0"
    path_append /gnupg
    path_append "/Program Files/R/R-2.14.0/bin"
    path_append "/Program Files (x86)/Lua/5.1"
    path_append "/Program Files/GraphicsMagick-1.3.7-Q16"
    path_append "/Program files/Mercurial"
    path_append "/Program Files/TortoiseHg"
    # # Tex/LaTeX (http://tug.org/texlive/)
    path_append /texlive/2010/bin/win32
    path_append /Windows
    path_append /Windows/system32
    path_append "/Program Files (x86)/PuTTY" # for plink (ssh)
    path_append "$VS10/VC/Bin"
    path_append "$VS10/Bin"
}

setpath_windows() {
    path_append "/Program files/Mercurial"
    path_append "/Program Files/TortoiseHg"
    # # Tex/LaTeX (http://tug.org/texlive/)
    path_append /texlive/2010/bin/win32
    path_append /Windows
    path_append /Windows/system32
    path_append "/Program Files (x86)/PuTTY" # for plink (ssh)
}

setpath() {
    : generic version: nothing here
}

# set up path.  Only do this once, to avoid duplicates.
if ! ( echo "$PATH" | grep -q PATHSETFROM ); then
    path_prepend /PATHSETFROMBASH
    machine_setpath=setpath_`uname -n`
    os_setpath=setpath_$OS
    if declare -f "$machine_setpath" >/dev/null; then
      $machine_setpath
    elif declare -f "$os_setpath" >/dev/null; then
      $os_setpath
    else
      setpath
    fi
    path_append .
fi

########################################################################
# Terminal setup

ttymodes=(-istrip erase \^h susp \^Z intr \^C quit \^\\ flush \^O ixany)
if [[ $TERM = emacs ]]; then
  :
else
  stty $ttymodes
fi


########################################################################
# Variables, shell functions and aliases

# if [[ -n "$ZSH_VERSION" ]]; then echo Running zsh; fi
# if [[ -n "$BASH_VERSION" ]]; then echo Running bash; fi

if [[ -n "$ZSH_VERSION" ]]; then
  HISTFILE=~/.zhistory
  # I omit () {} = and / so we stop on those
  WORDCHARS="*?_-.[]~&;\!#$%^<>"
else
  HISTFILE=~/.history
fi
SAVEHIST=300
HISTSIZE=1000
NUMERICGLOBSORT=1
READNULLCMD=less
TIMEFMT="%J:
	%U(u)+%S(s)/%E=%P.
	%W swap, %Kk(max %M), pf=%F+%R,
	%Ii/%Oo, sock=%ri/%so, %k sigs, csw=%w vol/%c invol."
REPORTTIME=15
fignore=( .adm .sbin3 .sbin4 .vbin 0~ 1~ 2~ 3~ 4~ 5~ 6~ 7~ 8~ 9~
    .obj .pdb .bsc .ilk .idb  .OBJ .PDB .BSC .ILK .IDB)

if [[ -e c:/bin2/emacs-garyo.sh ]]; then
  export EDITOR='c:/bin2/emacs-garyo.sh' # wrapper for emacsclientw
else
  export EDITOR=emacs
fi
export EXINIT='set redraw sw=2 wm=2'
export LESS='-eij3Mqs'
export LESSOPEN='|lessopen.sh %s'
export MORE=s
export PAGER='less'
export PGPPATH=$HOME/.pgp
if [[ $TERM = emacs || $TERM = dumb ]]; then
  export PAGER=
  export GIT_PAGER=
fi

# 10 most recently modified files
function la()
{
  ls -lt "$@" | head -10
}

alias -- ls='ls -CF'
alias -- m='less'
alias -- which='type -a'
alias -- 1='pushd +1'
alias -- 2='pushd +2'
alias -- 3='pushd +3'
alias -- 4='pushd +4'
alias -- 5='pushd +5'
alias -- 6='pushd +6'
alias -- sc='. ~/.bashrc'
alias -- d='dirs -v'
alias -- df='df -k'
alias -- j='jobs -l'
alias -- ll='ls -l'
alias -- tf='tail -f'

########################################################################
# Shell options

if [[ -n "$ZSH_VERSION" ]]; then
  setopt autolist automenu autopushd autoresume
  setopt extendedglob glob_dots
  setopt histignoredups ignoreeof listtypes longlistjobs
  setopt nobadpattern nonomatch notify pushdignoredups pushdsilent
  setopt rcquotes nolistbeep
  setopt appendhistory histexpiredupsfirst histfindnodups histsavenodups incappendhistory extendedhistory
  DIRSTACKSIZE=7

  # If emacs, make like normal shell
  if [[ $TERM = emacs || $TERM = dumb ]]; then
    unsetopt ZLE
  fi
fi

########################################################################
# Prompt

if [[ X$VENDOR = Xpc ]]; then
PROMPT='%m (%~) %@ %! =>
%# '
PROMPT2='MORE: => '
else
PROMPT='%U%m (%~) %@ %B%!=>%b%u
%# %B'
PROMPT2='%U%m%u %U%B%UMORE:%u%b %B=>%b '
#POSTEDIT=`echotc me`	# turn off all attributes
fi
RPROMPT=

# Only set chpwd (or prompt) to echo to xterm title bar if on an xterm
if [[ -n "$ZSH_VERSION" ]]; then
  chpwd () { [[ $TERM = xterm ]] && print -Pn ']2;%m (%l): %~' > /dev/tty; }
  if [[ $TERM = xterm ]]; then
    set PROMPT='%{]2;%m (%l): %~%}'$PROMPT
  fi
fi

# end of file

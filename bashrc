#!/bin/bash
# .bashrc for Gary Oberbrunner, 2012

# This is executed directly by bash if interactive and non-login,
# otherwise I source this from .profile or .zshrc/.kshrc
# (but only for interactive shells -- this should not be run for noninteractive shells)


# set for debugging:
# set -v
# set -x
# echo "Incoming PATH:"
# echo $path | tr ':' '\n'

if [ -z "$ZSH_VERSION" -a -z "$BASH" ]; then
    SIMPLE_SH_MODE=1
    return # the rest of this file assumes at least bash or zsh.
fi

if [[ "$OSTYPE" = cygwin && "$EMACS" = t ]]; then
  # Ugly, but otherwise emacs thinks it's cygwin.  Not sure why.
  OSTYPE=msys
fi

case $OSTYPE in
  cygwin*) OS=windows ;;
  msys*)   OS=windows ;;
  win*)    OS=windows ;;
  darwin*) OS=mac ;;
  *)       OS=linux ;;
esac
if [[ -n "$ZSH_VERSION" ]]; then
  MACHINENAME=${${HOST%%.*}:l}
else
  if [[ -n "$HOSTNAME" ]]; then
    MACHINENAME="$HOSTNAME"
  elif [[ -n "$COMPUTERNAME" ]]; then
    MACHINENAME="$COMPUTERNAME"
  else
    MACHINENAME=${HOST%%.*}      # strip domain
    MACHINENAME=`echo $MACHINENAME | tr '[A-Z]' '[a-z]'` # lowercase (${VAR,,} only works on bash 4.x)
  fi
fi
# echo MACHINENAME is $MACHINENAME

case $OSTYPE in
  cygwin*)
      export CYGWIN="nodosfilewarning"
      ;;
  msys*)
      export CYGWIN="nodosfilewarning"
      export MSYS=winsymlinks:nativestrict
      export MSYSTEM=MSYS
      ;;
esac

# utility to see if command is defined (in any way)
has_command () { command -v "$1" > /dev/null 2>&1 ; }

########################################################################
# Misc stuff
umask 2

########################################################################
# PATH setup

path_append ()  { path_remove "$1"; export PATH="$PATH:$1"; }
path_prepend () { path_remove "$1"; export PATH="$1:$PATH"; }
path_remove ()  {
    REMOVE="$1"
    if [[ -n "$ZSH_VERSION" ]]; then
      PATH=$(IFS=':';t=($PATH);unset IFS;t=(${t[@]%%$REMOVE});IFS=':';echo "${t[*]}");
    else
      IFS=':'
      t=($PATH)
      n=${#t[*]}
      a=()
      for ((i=0;i<n;i++)); do
	p="${t[i]%%$REMOVE}"
	[ "${p}" ] && a[i]="${p}"
      done
      PATH="${a[*]}"
    fi
}

setpath_noise() {
    VC10="/Program Files (x86)/Microsoft Visual Studio 10.0/VC"
    VS10="/Program Files (x86)/Microsoft Visual Studio 10.0"
    path_append /gnupg
    path_append "/Program Files/R/R-2.14.0/bin"
    path_append "/Program Files (x86)/Lua/5.1"
    path_append "/Program Files/GraphicsMagick-1.3.7-Q16"
    path_append "/Program files/Mercurial"
    path_append "/Program files (x86)/Mercurial"
    path_append "/Program Files/TortoiseHg"
    path_append "/Program Files/KDiff3"
    path_append "/c/Program Files (x86)/GnuWin32/bin"
    path_append "/Users/garyo/src/gccxml/build/bin/Debug" # for gccxml
    # Tex/LaTeX (http://tug.org/texlive/)
    path_append /texlive/2010/bin/win32
    # LibreOffice (soffice.exe) - for converting odt to docx in emacs
    path_append "/Program files (x86)/LibreOffice 4/program"
    path_append /Windows
    path_append /Windows/system32
    path_append "/Program Files (x86)/PuTTY" # for plink (ssh)
    path_append "$VS10/Common7/IDE" # DLLs for dumpbin
    path_append "$VC10/Bin"
    path_append "$VS10/Bin"
    path_append "/c/Program Files (x86)/Windows Kits/10/Debuggers/x64" # for WinDBG
    case $OSTYPE in
	cygwin*) # msys2 comes with git
	    path_append "/Program files (x86)/Git/cmd"
	    path_prepend /bin
	    ;;
    esac
    # for "wish", used by gitk:
    path_prepend /mingw64/bin

    path_prepend "/Python27"
    path_prepend "/Python27/Scripts"
    path_prepend "/Program Files (x86)"/GNU/GNUPG  # for gpg; use "gpg2"
    path_prepend /usr/bin
}
setpath_simplex() {
    # Simplex is my new work machine (2013), same config as noise
    setpath_noise
}

setpath_simplex_msys_emacs() {
    # This is just for building emacs with msys
    PATH=/FOR_MSYS:/bin:/usr/bin:/sbin:/mingw/bin:/c/Users/garyo/bin
}

setpath_windows() {
    path_prepend "/Python26"
    path_prepend "/Python27"
    path_prepend "/Python27/Scripts"
    # path_prepend /bin
    path_prepend /msys64
    case $OSTYPE in
	cygwin*) # msys2 comes with git
	    path_append "/Program files (x86)/Git/cmd" ;;
    esac
    path_append "/Program files/Mercurial"
    path_append "/Program Files/TortoiseHg"
    # # Tex/LaTeX (http://tug.org/texlive/)
    path_append /texlive/2010/bin/win32
    path_append /Windows
    path_append /Windows/system32
    path_append "/Program Files (x86)/PuTTY" # for plink (ssh)
    path_append "/swig"
}

setpath_mac() {
    path_append $HOME/bin
    path_append /usr/local/sbin
    path_append /usr/local/bin
    path_append /usr/sbin
    path_append /sbin
    path_append /Applications/Xcode.app/Contents/Developer/usr/bin
    path_prepend /Applications/Emacs.app/Contents/MacOS/bin-x86_64-10_9
    path_prepend /usr/local/Homebrew/bin # put this first in path, so last here
}

setpath() {
    path_append $HOME/bin
    path_append /usr/local/sbin
    path_append /usr/sbin
    path_append /sbin
}

maybe_setpath() {
    # set up path.  Only do this once, to avoid duplicates.
    if ! [[ "$PATH" == *PATHSETFROM* ]]; then
	ORIG_PATH="$PATH"
	path_prepend /PATHSETFROMBASH
	machine_setpath=setpath_$MACHINENAME
	machine_os_setpath=setpath_${MACHINENAME}_${OSTYPE} # really only for msys on simplex
	# echo "machine os setpath = " $machine_os_setpath
	os_setpath=setpath_$OS
	if declare -f "$machine_os_setpath" >/dev/null; then
	    $machine_os_setpath
	elif declare -f "$machine_setpath" >/dev/null; then
	    $machine_setpath
	elif declare -f "$os_setpath" >/dev/null; then
	    $os_setpath
	else
	    setpath
	fi
	path_append .
    fi
}

reset_path() {
    export PATH="$ORIG_PATH"
    maybe_setpath
}

# Now do it
maybe_setpath

########################################################################
# Terminal setup

if [[ $TERM = xterm-256color ]]; then  # get this coming from a Mac via ssh
  TERM=xterm
fi

ttymodes=(-istrip erase \^\? susp \^Z intr \^C quit \^\\ flush \^O ixany)
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
LC_ALL=C			# use regular "C" locale, fixes man pages
LANG=C
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
  export EDITOR='emacsclient -c -a ""'
fi
export EXINIT='set redraw sw=2 wm=2'
export GTAGSFORCECPP=1 # for GNU Global tags
export LESS='-eij3MqsFXR'
#export LESSOPEN='|lessopen.sh %s'
export MORE=s
export PAGER='less'
export PERLDOC=-t
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

alias ls='ls -CF'
alias m='less'
alias which='type -a'
alias 1='pushd +1'
alias 2='pushd +2'
alias 3='pushd +3'
alias 4='pushd +4'
alias 5='pushd +5'
alias 6='pushd +6'
alias sc='. ~/.bashrc'
alias d='dirs -v'
alias df='df -k'
alias j='jobs -l'
alias ll='ls -l'
alias tf='tail -f'

if [[ $OS = windows ]]; then
  if [[ $OSTYPE != msys ]]; then
    alias git="c:/Program\ Files\ \(x86\)/git/bin/git"
  fi
  # start on Windows opens a file with its default application.
  # It's a builtin in cmd.exe.
  function start()  {
    cmd /c "start /B $@"
  }
fi

if [[ $OS = mac ]]; then
    # GenArts custom python
    alias gapy="/usr/local/python2.7-64-genarts/python/bin/python"
fi

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

# multiline highlighted prompt
# PROMPT='%U%m (%~) %@ %B%!=>%b%u
setopt PROMPT_SUBST
if has_command cygpath ; then
  # use cygpath so Emacs dirtrack mode can track it
  PROMPT='%U%m (%{$(cygpath -m `pwd`)%}) %@ %B%!=>%b%u
%# %B'
  PROMPT2='%U%m%u %U%B%UMORE:%u%b %B=>%b '
else
  PROMPT='%U%m (%~) %@ %B%!=>%b%u
%# %B'
  PROMPT2='%U%m%u %U%B%UMORE:%u%b %B=>%b '
fi
if has_command echotc ; then
  POSTEDIT=`echotc me`	# turn off all attributes
fi
RPROMPT=

# For bash, nothing fancy but better than default:
if [[ -n "$BASH_VERSION" ]]; then
  PS1='\h [\W] % '
fi

# Only set chpwd (or prompt) to echo to xterm title bar if on an xterm
if [[ -n "$ZSH_VERSION" ]]; then
  chpwd () { [[ $TERM = xterm ]] && print -Pn ']2;%m (%l): %~' > /dev/tty; }
  if [[ $TERM = xterm ]]; then
    set PROMPT='%{]2;%m (%l): %~%}'$PROMPT
  fi
fi

if [[ "$TERM" != "dumb" && "$TERM" != "emacs" ]] ; then
    if has_command dircolors ; then
      eval "`dircolors -b`"
      alias ls='ls -CF --color=auto'
    fi
fi

# end of file

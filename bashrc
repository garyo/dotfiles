#!/bin/bash
# .bashrc for Gary Oberbrunner, 2012-2018

# This is executed directly by bash if interactive and non-login,
# otherwise I source this from .profile or .zshrc/.kshrc
# (but only for interactive shells -- this should not be run for noninteractive shells)


# set for debugging:
# set -v
# set -x
#echo "Incoming PATH:"
#echo $PATH | tr ':' '\n'
#echo "Incoming env:"
#env

if [ -z "$ZSH_VERSION" -a -z "$BASH" ]; then
    SIMPLE_SH_MODE=1
    return # the rest of this file assumes at least bash or zsh.
fi

if [[ "$OSTYPE" = cygwin && "$EMACS" = t ]]; then
  # Ugly, but otherwise emacs thinks it's cygwin.  Not sure why.
  OSTYPE=msys
fi

case $OSTYPE in
  cygwin*) _OS=windows ;;
  msys*)   _OS=windows ;;
  win*)    _OS=windows ;;
  darwin*) _OS=mac ;;
  *)       _OS=linux ;;
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
      # NO, don't do these: (would break python virtualenvwrapper)
      # export MSYSTEM=MSYS
      # export MSYS_HOME="$(cygpath -m /)"
      export MSYSTEM=MINGW64    # virtualenvwrapper seems to like this
      ;;
esac

# utility to see if command is defined (in any way)
has_command () { command -v "$1" > /dev/null 2>&1 ; }

########################################################################
# Misc stuff
umask 2

########################################################################
# PATH setup

path_append ()  {
    path_remove "$1"; export PATH="$PATH:$1";
    [[ -n $SETPATH_VERBOSE ]] && echo "PATH: Appending $1"
}
path_prepend () {
    path_remove "$1"; export PATH="$1:$PATH";
    [[ -n $SETPATH_VERBOSE ]] && echo "PATH: Prepending $1"
}
path_remove ()  {
    [[ -n $SETPATH_VERBOSE ]] && echo "PATH: removing $1"
    if [[ -n "$ZSH_VERSION" ]]; then
      path_remove_zsh "$1"
    else
      REMOVE="$1"
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

path_remove_zsh () {
    to_remove=($1)
    path=(${path:|to_remove})
}

# OLD
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
    path_prepend /msys64/usr/bin
    path_prepend /mingw64/bin # mingw compiler etc., from msys shell
    path_prepend "/Program Files (x86)"/GNU/GNUPG  # for gpg; use "gpg2"
    path_prepend /usr/bin
    path_prepend /usr/local/bin
    path_prepend "/c/Python27"
    path_prepend "/c/Python27/Scripts"
}

setpath_simplex_msys_emacs() {
    # This is just for building emacs with msys
    PATH=/FOR_MSYS:/bin:/usr/bin:/sbin:/mingw/bin:/c/Users/garyo/bin
}

setpath_tower1_msys() {
    path_prepend "/bin"
    path_prepend "/c/Program Files/git/bin"
    path_prepend "/c/Program Files/git LFS"
    path_prepend /msys64
    path_prepend /c/Windows/System32/OpenSSH # for ssh-add etc.
    path_prepend "/c/Program Files/nodejs"
    # path_prepend /mingw64/bin       # git lfs is here, but I copied it to c:/bin
    # path_prepend /c/emacs/emacs/bin # emacsclient
    path_prepend /c/ProgramData/chocolatey/bin # runemacs/emacs, putty etc.
    path_prepend "/c/Program Files/GnuGlobal/bin"
    path_prepend /c/bin # ffmpeg etc.
    # path_prepend "/c/Users/garyo/Anaconda3" # Anaconda python
    path_prepend "/c/Python37"  # Standard python
    path_prepend "/c/Python37/Scripts" # pip
    path_append "/c/Program Files/Cppcheck" # cppcheck, useful utility
    # dumpbin.exe:
    path_append "/c/Program Files (x86)/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.12.25827/bin/Hostx64/x64"
}

setpath_windows() {
    path_prepend "/c/Python36"
    path_prepend "/c/Python36/Scripts"
    path_prepend "/Python37"
    path_prepend "/Python37/Scripts"
    # path_prepend /bin
    path_prepend /msys64
    path_prepend /usr/bin # for msys2 bash/zsh
    path_prepend /mingw64/bin # mingw compiler etc., from msys shell
    case $OSTYPE in
	cygwin*) # msys2 comes with git
	    path_append "/Program files (x86)/Git/cmd" ;;
    esac
    # # Tex/LaTeX (http://tug.org/texlive/)
    path_append /texlive/2010/bin/win32
    path_append /c/Windows
    path_append /c/Windows/system32
    path_append "/c/Program Files (x86)/PuTTY" # for plink (ssh)
    path_prepend "/c/bin" # local programs e.g. git-lfs
    path_append "/c/Program Files/GnuGlobal/bin"
    path_append "/swig"
}

setpath_mac() {
    path_append /usr/local/sbin
    path_append /usr/local/bin
    path_append /usr/sbin
    path_append /sbin
    path_append /Applications/Xcode.app/Contents/Developer/usr/bin
    path_append /usr/local/opt/llvm/bin # for clangd, C++ LSP server
    path_prepend /Applications/Emacs.app/Contents/MacOS/bin-x86_64-10_9
    path_prepend /usr/local/lib/ruby/gems/2.6.0/bin
    path_prepend /usr/local/opt/ruby/bin
    path_prepend /usr/local/Homebrew/bin # put this first in path, so last here
    path_prepend $HOME/Library/Python/3.6/bin # pipenv, before homebrew
    path_prepend $HOME/python36/bin # virtualenv python in home dir
    path_prepend /usr/local/opt/go/libexec/bin # Go itself (the language, not the game)
    path_prepend $HOME/go/bin # Go programs
}

setpath() {
    path_append /usr/local/sbin
    path_append /usr/sbin
    path_append /sbin
    [[ -d ~/anaconda3/bin ]] && path_prepend ~/anaconda3/bin
    [[ -d ~/.local/bin ]] && path_prepend ~/.local/bin # for virtualenv & virtualenvwrapper
}

# Runs after all other setpaths, always
setpath_all() {
    path_prepend $HOME/.poetry/bin # Python dependency/virtualenv manager
    path_prepend $HOME/bin
    path_append "./node_modules/.bin" # for Node.js
    if has_command yarn; then
        path_append $(yarn global bin)
    fi
    path_append .
}

maybe_setpath() {
    # set up path.  Only do this once, to avoid duplicates.
    [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: maybe_setpath"
    if ! [[ "$PATH" == *PATHSETFROM* ]]; then
        [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: setting path, orig=$PATH"
	export ORIG_PATH="$PATH"
	path_append /PATHSETFROMBASH
	machine_setpath=setpath_$MACHINENAME
	machine_os_setpath=setpath_${MACHINENAME}_${OSTYPE} # really only for msys on simplex
	# echo "machine os setpath = " $machine_os_setpath
	os_setpath=setpath_$_OS
	if declare -f "$machine_os_setpath" >/dev/null; then
	    $machine_os_setpath
	elif declare -f "$machine_setpath" >/dev/null; then
	    $machine_setpath
	elif declare -f "$os_setpath" >/dev/null; then
	    $os_setpath
	else
	    setpath
	fi
        setpath_all           # always run this at end for paths to always add
    fi
}

reset_path() {
    export PATH="$ORIG_PATH"
    path_remove /PATHSETFROMBASH
    maybe_setpath
}
show_path() {
    echo "$PATH" | tr ':' '\n'
}

# Now do it
maybe_setpath

setvars_dev-mac() {
    # Commonly used dirs, easy to cd to and display in prompt
    # "cd ~RV"
    hash -d FLOSS=~/dss/consulting/spontaneous/FLOSS/src
    hash -d RV=~/dss/consulting/revision/revision-licensing
    hash -d SL=~/dss/consulting/shorelight
}

setvars_surfpro4_linux() {
    setvars_tower1_linux        # WSL, same setup
}

# Do machine or OS-specific variable setup
# Unlike setpath, calls *all* existing funcs
setvars() {
    machine_setvars=setvars_$MACHINENAME
    machine_os_setvars=setvars_${MACHINENAME}_${_OS}
    os_setvars=setvars_$_OS
    # Most specific last so it wins
    declare -f "$os_setvars" >/dev/null         && $os_setvars
    declare -f "$machine_setvars" >/dev/null    && $machine_setvars
    declare -f "$machine_os_setvars" >/dev/null && $machine_os_setvars
}
# now do it
setvars

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

# ssh-pageant
# see https://github.com/cuviper/ssh-pageant
if [[ -f /usr/bin/ssh-pageant ]]; then
  eval $(/usr/bin/ssh-pageant -r -a "/tmp/.ssh-pageant-$USERNAME")
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
SAVEHIST=5000
HISTSIZE=9999
NUMERICGLOBSORT=1
READNULLCMD=less
# Locale
export LC_ALL=          # this overrides all other locale settings, keep blank
export LANG=en_US.utf-8 # use utf-8 for everything, except specific LC_*
export LC_COLLATE=C     # sort dotfiles first, use ASCII ordering
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

if [[ -e "$HOME/pythonstartup" ]]; then
  export PYTHONSTARTUP="$HOME/.pythonstartup"
fi

# 10 most recently modified files
function la()
{
  ls -lt "$@" | head -10
}

function gdrive-upload()
{
    rclone copy "$1"  borisfx-gdrive:"Boris FX/$2"
}

# History of most recent 50 (or arg) commands, with timestamps
function h()
{
    fc -li -${1:-50}
}

function sc()
{
    . ~/.bashrc
    reset_path
}

function dos2unix()
{
    # this looks funny but it works -- replaces all backslashes with fwd
    echo ${1//\\//} | sed 's,^[cC]:,/mnt/c,'
}

alias ls='ls -CF'
alias m='less'
alias f='find . -name'
# alias which='type -a'
alias which='command -v'
alias d='dirs -v'
alias df='df -h'
alias j='jobs -l'
alias ll='ls -l'
alias tf='tail -f'
alias t='tree -I __pycache__\|*.pyc\|node_modules'

# Show file tree, ignoring git-ignored files/dirs.
function gtree {
    git_ignore_files=("$(git config --get core.excludesfile)" .gitignore ~/.gitignore)
    ignore_pattern="$(grep -hvE '^$|^#' "${git_ignore_files[@]}" 2>/dev/null|sed 's:/$::'|sed 's:^/::'|tr '\n' '\|')"
    if git status &> /dev/null && [[ -n "${ignore_pattern}" ]]; then
      tree -I "${ignore_pattern}" "${@}"
    else
      tree "${@}"
    fi
}

if [[ -n "$ZSH_VERSION" ]]; then
    # these cd to that dir in the stack, pushing the others down
    alias 1='cd ~1'
    alias 2='cd ~2'
    alias 3='cd ~3'
    alias 4='cd ~4'
    alias 5='cd ~5'
    alias 6='cd ~6'
    # this seems odd, but it just rotates the dir stack (so it's similar to 1,2,3)
    alias 0='pushd +1'
fi

if [[ $_OS = windows ]]; then
  if [[ $OSTYPE != msys ]]; then
    alias git="c:/Program\ Files\ \(x86\)/git/bin/git"
  fi
  if [[ $OSTYPE = msys && -e c:/msys64/usr/bin/ssh.exe ]]; then
    # git will find ssh without this, but git-lfs will not. So set it explicitly.
    export GIT_SSH_COMMAND=c:/msys64/usr/bin/ssh.exe
  fi
  # start on Windows opens a file with its default application.
  # It's a builtin in cmd.exe.
  function start()  {
    cmd /c "start /B $@"
  }
fi

function whatshell {
  ps -p $$
}

########################################################################
# Shell options

if [[ -n "$ZSH_VERSION" ]]; then
  setopt autolist automenu autopushd autoresume
  setopt extendedglob glob_dots
  setopt histignoredups ignoreeof listtypes longlistjobs
  setopt nobadpattern nonomatch notify pushdignoredups pushdsilent
  setopt rcquotes nolistbeep
  setopt appendhistory histexpiredupsfirst histfindnodups histsavenodups incappendhistory extendedhistory
  autoload -U zmv # fancy batch rename utility
  DIRSTACKSIZE=10

  # If emacs, make like normal shell
  if [[ $TERM = emacs || $TERM = dumb ]]; then
    unsetopt ZLE
  fi
fi

########################################################################
# Prompt

#git_prompt() {
# ref=$(git symbolic-ref HEAD | cut -d'/' -f3-)
# echo $ref
#}

if [[ -n "$ZSH_VERSION" && -z "$has_vcs_info" ]]; then
    autoload -Uz vcs_info
    if autoload +X vcs_info; then	# try to load it
	has_vcs_info=1
    else
	has_vcs_info=0
    fi
fi

if [[ $has_vcs_info -gt 0 ]]; then
    zstyle ':vcs_info:*' actionformats \
	   '%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f'
    zstyle ':vcs_info:*' formats       \
	   '%F{5}[%F{2}%b%F{5}]%f'
    zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'

    zstyle ':vcs_info:*' enable git
fi

# returns 0 (like exit status 0) if inside a git working dir/repo
# This is a cheap hack but it makes vcs_info_wrapper *much* faster
# when not in a git dir.
in_git_dir() {
    [[ -e .git ]] && return 0
    [[ -e ../.git ]] && return 0
    [[ -e ../../.git ]] && return 0
    [[ -e ../../../.git ]] && return 0
    [[ -e ../../../../.git ]] && return 0
    return 1
}

# or use pre_cmd, see man zshcontrib
vcs_info_wrapper() {
  if in_git_dir; then
     [[ $has_vcs_info -eq 1 ]] && vcs_info
     if [ -n "$vcs_info_msg_0_" ]; then
       echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
     else
       echo "[$(git rev-parse --abbrev-ref HEAD 2>/dev/null)]"
     fi
  fi
}

# multiline highlighted prompt
# PROMPT='%U%m (%~) %@ %B%!=>%b%u
if [[ -n "$ZSH_VERSION" ]]; then
    setopt PROMPT_SUBST
fi
if [[ $TERM == dumb ]]; then
  PROMPT="> "
elif has_command cygpath && [[ $TERM == emacs ]] ; then
  # use cygpath so Emacs dirtrack mode can track it
  PROMPT='%U%m (%F{yellow}%{$(cygpath -m "`pwd`")%}%f $(vcs_info_wrapper)) %@ %B%!=>%b%u
%# %B'
  PROMPT2='%U%m%u %U%B%UMORE:%u%b %B=>%b '
else
  PROMPT='%U%m (%F{yellow}%~%f $(vcs_info_wrapper)) %@ %B%!=>%b%u
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

# If it's a login shell, start ssh-agent.
if [[ -n "$ZSH_VERSION" ]]; then
    [[ -o login ]]
    IS_LOGIN=$?
else
    shopt -q login_shell
    IS_LOGIN=$?
fi

# 0 means true here
if [[ $IS_LOGIN == 0 ]] && [[ -z "$SSH_AUTH_SOCK" ]]; then
   # Try using a fixed location for SSH_AUTH_SOCK systemwide
   export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$NAME.sock
   # Can we connect to a running agent?
   ssh-add -l 2>/dev/null >/dev/null
   _STATUS=$?
   # echo ssh add status = $_STATUS
   if [ $_STATUS -ge 2 ]; then  # didn't work
       echo "No running ssh agent; starting new one with $SSH_AUTH_SOCK"
       rm -f "$SSH_AUTH_SOCK"
       eval $(ssh-agent -a $SSH_AUTH_SOCK) >& /dev/null
   fi
fi

########################################################################
# Completion plugins
########################################################################

if [[ -n "$ZSH_VERSION" ]]; then
    if [[ ! -f ~/antigen.zsh ]]; then
        curl -L git.io/antigen > ~/antigen.zsh
    fi
    source ~/antigen.zsh
    antigen bundle git >& /dev/null
    antigen bundle zsh-users/zsh-completions >& /dev/null
    antigen apply
fi

if [[ -f ~/Dotfiles/bashrc.local ]]; then
    source ~/Dotfiles/bashrc.local
fi
if [[ -f ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi

########################################################################
# Python virtualenvwrapper
#
# NOTE: I'm using my own trivial "venv" rather than official
# virtualenvwrapper since it's not being maintained anymore.
# My own "venv" just allows workon, create, and list.
# It's basically compatible with virtualenvwrapper; uses same dir for envs.
########################################################################

WORKON_HOME=$HOME/.virtualenvs
# VIRTUALENVWRAPPER_PYTHON must be full path
if has_command "python3"; then
    export VIRTUALENVWRAPPER_PYTHON=$(which python3)
else
    export VIRTUALENVWRAPPER_PYTHON=$(which python)
fi

# Puts virtualenvs in ~/.virtualenvs or WORKON_HOME
# To use:
#  mkvirtualenv <envname> (-r requirements_file)
#  workon <envname>
#  deactivate
#  "workon" by itself lists envs
#  showvirtualenv
#  cdvirtualenv, cdsitepackages, lssitepackages
#  virtualenvwrapper: prints basic help & cmd list
#  mktmpenv (deleted when deactivated)
#  lsvirtualenv
# NOTE: if it doesn't work, try VIRTUALENVWRAPPER_VIRTUALENV='python -mvenv'
# To install initially, `python -mpip install [--user] virtualenvwrapper`
setup_virtualenvwrapper()
{
    scripts_dirs=()
    if [[ $_OS == windows ]]; then
        pythonpath=$(/bin/ls -d c:/Python*|tail -1)
        scripts_dirs+=("$pythonpath/Scripts")
    else
        scripts_dirs+=($($VIRTUALENVWRAPPER_PYTHON -c 'import site; print(site.USER_BASE)'))
        scripts_dirs+=('/usr/local/bin')
    fi
    for dir in $scripts_dirs; do
        # echo Checking for virtualenvwrapper.sh in $dir of $scripts_dirs
        if [[ -f "$dir/bin/virtualenvwrapper.sh" ]]; then
            source "$dir/bin/virtualenvwrapper.sh"
            return
        elif [[ -f "$dir/virtualenvwrapper.sh" ]]; then
            source "$dir/virtualenvwrapper.sh"
            return
        fi
    done
}
#### I'm not using this -- see "venv" below
setup_virtualenvwrapper

#### virtualenvwrapper alternative: simple command to list and activate

function venv ()
{
    if [[ $_OS == windows ]]; then
        VIRTUALENV_BINDIR=Scripts
    else
        VIRTUALENV_BINDIR=bin
    fi
    if [[ $# == 0 ]]; then
        cmd="help"
    else
        cmd=$1; shift
    fi
    case $cmd in
        workon)
            env=$1; shift
            source $WORKON_HOME/$env/$VIRTUALENV_BINDIR/activate
            ;;
        list)
            (cd $WORKON_HOME ; ls -d */ | sed s,//,,g )
            ;;
        create)
            env=$1; shift
            echo Creating new virtualenv $env
            $VIRTUALENVWRAPPER_PYTHON -mvenv "$WORKON_HOME/$env"
            source "$WORKON_HOME/$env/$VIRTUALENV_BINDIR/activate"
            ;;
        *)
            echo "Usage: $0 workon <env>|list"
            ;;

    esac
}

function _venv_comp_simple () {
    venvs=$(cd $WORKON_HOME ; echo */ | sed s,/,,g )
    args=(
        # '(-h --help)'{-h+,--help}'[show this help message and exit]'
        # '(-)'--version'[display version information and exit]'
        '1:command:(list workon create)'
        "*::arguments:($venvs)"
    )
    _arguments -S $args
}

function _venv_comp () {
    ret=1
    venvs=$(cd $WORKON_HOME ; echo */ | sed s,/,,g )
    # First arg is subcommand (set state to "args"), then
    # complete args below depending on subcommand
    _arguments -C \
               '1: :(list workon create)' \
               '*::arg:->args' \
        && ret=0
    case $state in
        args)
            case $line[1] in
                list)
                    _message 'no more args' && ret=0
                    ;;
                workon)
                    # complete existing envs
                    _arguments "::env:($venvs)" && ret=0
                    ;;
                create)
                    # any name
                    _arguments "::env: " && ret=0
                    ;;
            esac
    esac
}

if has_command "compdef"; then
    compdef _venv_comp venv
fi

# I don't care that some dirs are other-writable, and I care about my eyes
export LS_COLORS=$(echo -n "$LS_COLORS"|sed 's/ow=[0-9]*;[0-9]*/ow=34;40/g')

# end of file

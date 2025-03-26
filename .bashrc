#!/bin/bash
# .bashrc for Gary Oberbrunner, 2012-2018

# This is executed directly by bash if interactive and non-login,
# otherwise I source this from .profile or .zshrc/.kshrc
# (but only for interactive shells -- this should not be run for noninteractive shells)

# set for debugging:
# set -v
# set -x
last_ts=0

# Set to 1 for timing info (this only works w/ zsh): enables zprof
# Set to 2 to also print times for known-slow operations
TIMEDIFF_ON=0
if [ -n "$ZSH_VERSION" ]; then
  [[ $TIMEDIFF_ON -gt 0 ]] && zmodload zsh/zprof
  timediff1 () {
      [[ $TIMEDIFF_ON -gt 1 ]] || return
      label=$1
      ts=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')
      delta=$(( ts - last_ts ))
      if [[ $last_ts -gt 0 ]]; then
          if [[ $delta -gt 1 ]]; then # long times: print in red
              echo "$label: [31m${delta}[39m sec since prev"
          else
              echo "$label: ${delta} sec since prev"
          fi
      fi
      last_ts=$ts
  }
else
  function timediff1() {
    /usr/bin/false
  }
fi

#echo "Incoming PATH:"
#echo $PATH | tr ':' '\n'
#echo "Incoming env:"
#env

timediff1 start
if [ -z "$ZSH_VERSION" ] && [ -z "$BASH" ]; then
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
  MACHINE_PART=${HOST%%.*}
  MACHINENAME=${MACHINE_PART:l}
else
  if [[ -n "$HOSTNAME" ]]; then
    MACHINENAME="$HOSTNAME"
  elif [[ -n "$COMPUTERNAME" ]]; then
    MACHINENAME="$COMPUTERNAME"
  else
    MACHINE_PART=${HOST%%.*}      # strip domain
    MACHINENAME=${MACHINE_PART,,}
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

PATH=$PATH:/bin:/usr/bin        # for grep at least (can be missing in msys2)

# utility to see if command is defined (in any way)
has_command () { command -v "$1" > /dev/null 2>&1 ; }

# utility to see if command is a shell function (zsh & bash are different)
# type -t returns "function" in bash, whence -w ends with "function" in zsh
is_function () {
    if [[ -n "$ZSH_VERSION" ]]; then
        whence -w "$1" | grep -q "function$"
    else
        [[ "$(type -t $1)" = "function" ]]
    fi
}

[[ -f /msys2.exe ]] && IS_MSYS2=1
[[ -n $WSLENV && -z $IS_MSYS2 ]] && IS_WSL=1
[[ -n $WSL_INTEROP ]] && IS_WSL2=1
[[ -e /etc/centos-release ]] && IS_CENTOS=1
[[ -e /etc/os-release ]] && grep -isq ubuntu /etc/os-release && IS_UBUNTU=1
[[ -n $IS_WSL2 && -n $IS_CENTOS ]] && WSL2_OSNAME="CENTOS"
[[ -n $IS_WSL2 && -n $IS_UBUNTU ]] && WSL2_OSNAME="UBUNTU"


########################################################################
# Misc stuff
umask 2

########################################################################
# PATH setup

# Uncomment for setpath debugging
# SETPATH_VERBOSE=1

# This is for speed, since we check for cygpath repeatedly
CYGPATH_AVAILABLE=
function has_cygpath {
  [[ -n "$CYGPATH_AVAILABLE" ]] && return 0
  if has_command cygpath; then
    CYGPATH_AVAILABLE=1
    return 0
  fi
  return 1
}

# Global cache (should be defined once)
typeset -gA CYGPATH_CACHE

# Usage: cached_cygpath "/some/path" resultvar
cached_cygpath() {
  local key=$1
  local __retvar=$2
  local val

  # Fast path: if no backslash or colon, assume it's already Unix-style
  if [[ $key != *[:\\]* ]]; then
    eval "$__retvar=\"\$key\""
    return
  fi

  if [[ -n ${CYGPATH_CACHE[$key]} ]]; then
    val=${CYGPATH_CACHE[$key]}
  else
    val=$(cygpath "$key")
    CYGPATH_CACHE[$key]=$val
    echo "cached_cygpath($key) = ${CYGPATH_CACHE[$key]}"
  fi

  eval "$__retvar=\"\$val\""
}

# Check if given path $1 exists
# Assume it's present if $2 is "always"
path_check () {
    [[ ${2:-ifexists} == always ]] && return 0
    if ! [[ -e $1 ]] ; then
        [[ -n $SETPATH_VERBOSE ]] && echo "Nonexistent path $1 -- not using"
        return 1
    fi
    return 0
}

# Check if $PATH contains dir (case sensitive, so beware on Windows)
path_contains_dir() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *)        return 1 ;;
  esac
}

# Append $1 to path; move to back if already in path.
# If $2 is "always", append to path even if it doesn't exist.
# Use cygpath on Windows to preprocess into cygwin/Unix style
path_append ()  {
    local P
    if has_cygpath; then
        cached_cygpath "$1" P
    else
        P="$1"
    fi
    local old=$PATH
    path_remove "$P"
    path_check "$P" "${2:-ifexists}" || return 1
    export PATH="$PATH:$P";
    [[ -n $SETPATH_VERBOSE ]] && echo "PATH: Appending $P"
}
# Prepend $1 to path; move to front if already in path.
# If $2 is "always", prepend to path even if it doesn't exist.
path_prepend () {
    path_remove "$1"
    path_check "$1" "${2:-ifexists}" || return 1
    export PATH="$1:$PATH";
    [[ -n $SETPATH_VERBOSE ]] && echo "PATH: Prepending $1"
}
path_remove ()  {
    [[ -n $SETPATH_VERBOSE ]] && echo "PATH: removing $1"
    local P
    if has_cygpath; then
        cached_cygpath "$1" P
    else
        P="$1"
    fi
    path_contains_dir "$1" || return 0  # Already absent, nothing to do

    if [[ -n "$ZSH_VERSION" ]]; then
      path_remove_zsh "$P"
    else
      REMOVE="$P"
      OLD_IFS="$IFS"
      IFS=':'
      t=($PATH)
      n=${#t[*]}
      a=()
      for ((i=0;i<n;i++)); do
	p="${t[i]%%$REMOVE}"
	[ "${p}" ] && a[i]="${p}"
      done
      PATH="${a[*]}"
      IFS="$OLD_IFS"
    fi
}

path_remove_zsh () {
    to_remove=($1)
    path=(${path:|to_remove})
}

setpath_simplex_msys_emacs() {
    # This is just for building emacs with msys
    PATH=/FOR_MSYS:/bin:/usr/bin:/sbin:/mingw/bin:/c/Users/garyo/bin
}

setpath_windows() {
    # path_prepend /bin
    path_prepend /msys64
    path_prepend /usr/bin # for msys2 bash/zsh
    path_prepend /mingw64/bin # mingw compiler etc., from msys shell
    case $OSTYPE in
	   cygwin*) # msys2 comes with git
	    path_append "/Program files (x86)/Git/cmd" ;;
    esac
    path_prepend "/c/Program Files/git LFS"
    path_prepend "/c/Program Files/git/bin"
    path_prepend "/c/Program Files/git/cmd"
    # # Tex/LaTeX (http://tug.org/texlive/)
    path_append /texlive/2010/bin/win32
    path_prepend /c/Windows/System32/OpenSSH # for ssh-add etc.
    path_prepend /c/bin always # ffmpeg etc.
    path_append /c/Windows
    path_append /c/Windows/system32
    path_append "/c/Program Files/Cppcheck" # cppcheck, useful utility
    path_prepend "/c/bin" always # local programs e.g. git-lfs
    path_append "$HOME/bin/_Dependencies" # list dll dependencies, exe is "Dependencies"
    path_append /c/ProgramData/chocolatey/bin # runemacs/emacs, putty etc.
}

setpath_mac() {
    path_prepend /usr/local/sbin
    path_prepend /usr/local/bin
    path_append /usr/sbin
    path_append /sbin
    path_append /Applications/Xcode.app/Contents/Developer/usr/bin
    path_append /usr/local/opt/llvm/bin # for clangd, C++ LSP server
    path_prepend /Applications/Emacs.app/Contents/MacOS/bin-x86_64-10_9
    path_prepend /Applications/Emacs.app/Contents/MacOS/bin # emacsclient may be here
    path_prepend /usr/local/lib/ruby/gems/2.6.0/bin
    path_prepend /usr/local/opt/ruby/bin
    path_prepend /usr/local/Homebrew/bin # put this first in path, so last here
    path_prepend /opt/homebrew/bin # M1 mac location
    path_prepend /usr/local/opt/go/libexec/bin # Go itself (the language, not the game)
    path_prepend $HOME/go/bin # Go programs
}

setpath() {
    path_append /usr/local/sbin
    path_append /usr/sbin
    path_append /sbin
}

# Runs after all other setpaths, always
setpath_all() {
    if has_command yarn; then
        local yarndir=$(yarn global bin)
        # don't move /usr/local/bin to front if it's already somewhere in $PATH
        # (on Mac that can get the wrong version of homebrew)
        path_contains_dir $yarndir || path_append $yarndir
    fi
    path_prepend $HOME/.poetry/bin always # Python dependency/virtualenv manager
    path_prepend $HOME/.local/bin always # alt path for poetry, maybe other things
    path_prepend $HOME/bin always
    path_append ./node_modules/.bin # for Node.js
    path_append .
}

setpath_fnm() {
    # use fnm -- much faster to start a shell than nvm
    if ! [[ -d ~/.fnm ]] && ! has_command fnm; then
        # echo "No fnm for node.js; Install fnm using `curl -fsSL https://fnm.vercel.app/install | bash`"
        return 1
    else
        # Install like this:
        #   curl -fsSL https://fnm.vercel.app/install | bash
        timediff1 "before nvm/fnm setup"
        export PATH=~/.fnm:$PATH
        eval "$(fnm env --use-on-cd)"
        timediff1 "after nvm/fnm base setup"
        return 0
    fi
}

setpath_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
}

# bun (fast JS/TS runtime, faster than node.js, runs typescript natively)
setpath_bun() {
    if [[ -d $HOME/.bun ]]; then
        export BUN_INSTALL="$HOME/.bun"
        path_append "$BUN_INSTALL/bin"
        if [[ $SHELL =~ zsh && -s "$HOME/.bun/_bun" ]]; then
            # bun shell completions
            source "$HOME/.bun/_bun"
        fi
    fi
}


# Note: this also sets up `uv` python virtualenv manager (because it's a rust program)
setpath_rust() {
    if [[ -d $HOME/.cargo ]]; then
        path_prepend "$HOME/.cargo/bin"
    fi
}

setpath_gcloud() {
    if [[ -d ~/google-cloud-sdk && $SHELL =~ zsh ]]; then
        source ~/google-cloud-sdk/path.zsh.inc
        source ~/google-cloud-sdk/completion.zsh.inc
    fi
}

setpath_linux() {
    if [[ $IS_WSL -gt 0 ]]; then
        path_remove '/mnt/c/Program Files/nodejs' # don't use Windows npm
        path_remove '/mnt/c/Program Files/Git/cmd'
        path_remove '/mnt/c/Program Files/Git LFS'
        path_remove '/mnt/c/Program Files (x86)/Yarn/bin'
        path_remove '/mnt/c/Program Files (x86)/Yarn/bin/'
        path_remove '/mnt/c/Program Files/Cmake/bin'
        path_remove '/mnt/c/Python37/Scripts'
        path_remove '/mnt/c/Users/garyo/.pyenv/pyenv-win/shims'
        path_remove '/mnt/c/Users/garyo/.pyenv/pyenv-win/bin'
    fi
    # Not sure these are needed
    path_append /usr/local/sbin
    path_append /usr/sbin
    path_append /sbin
}

setpath_pyenv() {
    # not needed for msys/pyenv-win; add pyenv to $PATH, $PYENV, etc. manually there
    path_prepend ~/.pyenv/bin # python/pyenv
    path_prepend ~/.pyenv/shims # python/pyenv (should be set by pyenv init)
    if has_command pyenv && [[ $OSTYPE != msys ]] ; then
        eval "$(pyenv init -)"
    fi
}

setpath_fzf() {
    # fzf: its install script creates ~/.fzf.zsh/bash which adds ~/.fzf/bin to $PATH
    [[ -n $ZSH_VERSION ]] && [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
}

setpath_winget() {
    if [[ $_OS = windows ]]; then
        path_append $(cygpath "$LOCALAPPDATA/Microsoft/WinGet/Links")
    fi
}


maybe_setpath() {
    # set up path.  Only do this once, to avoid duplicates.
    [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: maybe_setpath"
    if ! [[ "$PATH" == *PATHSETFROM* ]]; then
        [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: setting path, orig=$PATH"
	export ORIG_PATH="$PATH"
	PATH="${PATH}:/PATHSETFROMBASH"
	machine_setpath=setpath_$MACHINENAME
	machine_os_setpath=setpath_${MACHINENAME}_${OSTYPE} # really only for msys on simplex
	# echo "machine os setpath = " $machine_os_setpath
	os_setpath=setpath_$_OS
	if declare -f "$machine_os_setpath" >/dev/null; then
            [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: setting path via $machine_os_setpath"
	    $machine_os_setpath
	elif declare -f "$machine_setpath" >/dev/null; then
            [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: setting path via $machine_setpath"
	    $machine_setpath
	elif declare -f "$os_setpath" >/dev/null; then
            [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: setting path via $os_setpath"
	    $os_setpath
	else
            [[ -n $SETPATH_VERBOSE ]]  && echo "PATH: setting path via setpath"
	    setpath
	fi
        setpath_fnm || setpath_nvm
        setpath_bun
        setpath_rust
        setpath_pyenv
        setpath_gcloud
        setpath_fzf
        setpath_winget
        setpath_all           # always run this at end for paths to always add
    fi
}

reset_path() {
    export PATH="$ORIG_PATH"
    path_remove /PATHSETFROMBASH
    maybe_setpath
    if is_function setpath_local; then
        setpath_local
    fi
}
show_path() {
    echo "$PATH" | tr ':' '\n'
}

# Now do it
timediff1 "before setpath"
maybe_setpath
timediff1 "after setpath"

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

# All modern "256-color" terminals are really 24-bit, I think.
# So set COLORTERM to indicate that to clients.
# BUT NO, Mac Terminal is not!
[[ $TERM == xterm-256color && $_OS != mac ]] && export COLORTERM=24bit

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
SAVEHIST=10000
HISTSIZE=99999
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
elif has_command emacsclient; then
    export EDITOR='emacsclient -c -a ""'
else
    export EDITOR='vim'
fi
export GIT_EDITOR="$EDITOR"
export EXINIT='set redraw sw=2 wm=2'
export GTAGSFORCECPP=1 # for GNU Global tags
export LESS='-eij3MqsFXR'
#export LESSOPEN='|lessopen.sh %s'
export MORE=s
export PAGER='less'
[[ -f ~/.config/ripgrep.conf ]] && export RIPGREP_CONFIG_PATH=~/.config/ripgrep.conf
export PERLDOC=-t
export PGPPATH=$HOME/.pgp
export CLANGD_FLAGS="--header-insertion=never --header-insertion-decorators=0 --completion-style=detailed --clang-tidy --background-index --pch-storage=memory --log=error -j 8"
if [[ $TERM = emacs || $TERM = dumb ]]; then
  export PAGER=
  export GIT_PAGER=
fi

if [[ -e "$HOME/pythonstartup" ]]; then
  export PYTHONSTARTUP="$HOME/.pythonstartup"
fi

# 10 most recently modified files
if has_command eza; then
  function la()
  {
      eza -l -snew -r "$@" --color always | head -15
  }
else
  function la()
  {
      ls -lt "$@" | head -15
  }
fi

function edit()
{
    # allow word-splitting, prefer VISUAL, then EDITOR
    if [[ -n "$ZSH_VERSION" ]]; then
        ${=VISUAL:-${EDITOR:-vi}} "$@"
    else
        ${VISUAL:-${EDITOR:-vi}} "$@"
    fi
}

# Function to wait for SSH server to be available
function wait-ssh() {
    local server="$1"
    while true; do
        if ssh -o ConnectTimeout=5 "${server}" "exit" 2>/dev/null; then
            echo "SSH server at ${server} is up."
            return 0
        else
            echo "SSH server at ${server} not yet up. Retrying in 5 seconds..."
            sleep 5
        fi
    done
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

function dos2unix-path()
{
    # this looks funny but it works -- replaces all backslashes with fwd
    echo ${1//\\//} | sed 's,^[cC]:,/c,'
}

function webget()
{
    curl -sS --insecure "$@"
}

# POST using curl. Accpts JSON for data.
function webpost()
{
    curl -sS --insecure -X POST -H Content-Type:application/json "$@"
}

timediff1 "before WSL2 & X11"
# WSL2:
if has_command ipconfig.exe; then
    WSL_HOST_IP=$(ipconfig.exe | tr -d '\r' | grep -n4 WSL  | tail -n 1 |sed 's/.*: //')
fi

# Set up for X11
# Note: if we have WSL2 with XWayland, /mnt/wslg will exist, so we can use :0.0 and direct LIBGL.
# Note: on Rocky Linux 8 with Wayland (or maybe any session) we can't just set $DISPLAY. So avoid all of this if $WAYLAND_DISPLAY is set (but we do need to do it on WSLg).
# Might need to enhance this if on a HIDPI Wayland monitor.
if [ -z "$WAYLAND_DISPLAY" -o "$IS_WSL2" ]; then
    if [ -n "$WSL_HOST_IP" -a ! -e /mnt/wslg ]; then
	export DISPLAY="${WSL_HOST_IP}":0.0
    else
	export DISPLAY=:0.0  # local X server or WSLg w/ built-in Xwayland
    fi
    [ ! -e /mnt/wslg ] && export LIBGL_ALWAYS_INDIRECT=1
    if has_command xdpyinfo; then
	# resolution in dpi
	XRESOLUTION=$(xdpyinfo|grep resolution|head -1|sed 's/.*resolution: \+\([0-9]\+\)x[0-9].*\+/\1/') >&/dev/null
	# try again with :0.0 if it fails
	if [[ $? -ne 0 ]]; then
            export DISPLAY=:0.0
            XRESOLUTION=$(xdpyinfo|grep resolution|head -1|sed 's/.*resolution: \+\([0-9]\+\)x[0-9].*\+/\1/')
            [[ $? -ne 0 ]] && echo "Warning: can't open X11 display $DISPLAY"
	fi
	# Support HIDPI displays (Emacs menu bar for instance)
	if [ "$XRESOLUTION" -gt 150 ]; then
            export GDK_SCALE=0.5
            export GDK_DPI_SCALE=2
	else
            export GDK_SCALE=1
            export GDK_DPI_SCALE=1
	fi
    fi
fi # not WAYLAND_DISPLAY
timediff1 "after WSL2 & X11"

alias ls='ls -CF'
if has_command bat; then
    alias m='bat'
else
    alias m='less'
fi
if has_command fd; then
    alias f='fd'
else
    alias f='find . -name'
fi
# Zsh has many similar commands: which, type, whence, command, where.
# All bourne-like shells have "type" and "command -v"
# To get path of a command: "command -v"
# All cmds with given name:
#   - "where" in zsh (same as "whence -ca")
#   - "type -a" in bash or zsh
# "type" works for functions & aliases too (in zsh)
# generally, don't use "which" anymore -- it's builtin in zsh, but not elsewhere
# zsh:
#  whence is the base reference, takes many options
#  type = whence -v
#  command -v = whence
#  command -V = whence -v
#  where = whence -ca
#  which = whence -a
# I'll alias "which" to "type -a" to show everything
alias which="type -a" # show builtins, functions, aliases, and all in $PATH
alias d='dirs -v'
alias df='df -h'
alias j='jobs -l'
alias tf='tail -f'
if has_command eza; then
    alias t='eza --tree'
    alias ll='eza -lGF'
    alias lld='eza -lFd' # long listing of dirs (shows symlink targets)
else
    alias t='tree -I __pycache__\|*.pyc\|node_modules'
    alias ll='ls -l'
    alias lld='ls -ld'
fi

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
    alias 7='cd ~7'
    alias 8='cd ~8'
    alias 9='cd ~9'
    # this seems odd, but it just rotates the dir stack (so it's similar to 1,2,3)
    alias 0='pushd +1'
fi

function mcd {
    mkdir -p "$1"
    cd "$1" || return
}

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
  function start() {
      local args=()
      for arg in "$@"; do
          args+=("$(cygpath -m "$arg")")
      done
      c:/Windows/System32/cmd ////s ////c "start /B ${args[*]}"
  }

  # "open" is the Mac command to do this, might as well emulate on Windows
  function open()  {
      start "$@"
  }
fi

function whatshell {
  ps -p $$
}

function gcproject {
    if [[ -e ~/.config/gcloud/active_config ]]; then
        local configfile
        configfile=~/.config/gcloud/configurations/config_$(cat ~/.config/gcloud/active_config)
        if [[ $1 == "short" ]]; then
            # horizon-dev-123abc => dev
            awk '/^project/ {gsub(/-[0-9a-z]+$/, "", $3); print $3}' "$configfile"
        else
            awk '/^project/ {print $3}' "$configfile"
        fi
    fi
}

function gcproject_prompt {
    local p
    p=$(gcproject short)
    [[ -n $p ]] && echo "[GCP:$p]"
}

if has_command units; then
  command units -1 < /dev/null >& /dev/null
  if [[ $? -ne 0 ]]; then
      # old version of units; alias to `gunits` (e.g. brew install gnu-units on mac)
      alias units="gunits --verbose -1"
  else
      alias units="units --verbose -1"
  fi
fi

########################################################################
# Shell options

if [[ -n "$ZSH_VERSION" ]]; then
  setopt autolist automenu autopushd autoresume
  setopt extendedglob numericglobsort
  setopt ignoreeof listtypes longlistjobs
  setopt nobadpattern nonomatch notify pushdignoredups pushdsilent
  setopt rcquotes nolistbeep
  setopt histignoredups histexpiredupsfirst histfindnodups histsavenodups
  setopt incappendhistorytime extendedhistory
  autoload -U zmv # fancy batch rename utility
  bindkey -e # emacs keybindings
  DIRSTACKSIZE=10

  # If emacs, make like normal shell
  if [[ $TERM = emacs || $TERM = dumb ]]; then
    unsetopt ZLE
  else
    bindkey -em >& /dev/null
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

wsl_prompt() {
    if [[ $IS_WSL2 -gt 0 ]]; then
        echo -n '%F{83}\xf0\x9d\x9f\x9a%f' # unicode double-struck digit 2
        [[ $IS_CENTOS -gt 0 ]] && echo -n '%F{83}CENTOS%f '
    elif [[ $IS_WSL -gt 0 ]]; then
        echo -n '%F{160}\xf0\x9d\x9f\x99%f' # unicode double-struck digit 1
    elif [[ $IS_MSYS2 -gt 0 ]]; then
        echo -n '%F{160}\xf0\x9d\x95\x84%f' # unicode double-struck digit M
    fi
}

# multiline highlighted prompt
# PROMPT='%U%m (%~) %@ %B%!=>%b%u
if [[ -n "$ZSH_VERSION" ]]; then
    setopt PROMPT_SUBST
fi

mname_prompt() {
  [[ $USER == garyo ]] && echo -n "%m" || echo -n '%n@%m'
}

if [[ $TERM == dumb ]]; then
  PROMPT="> "
elif has_cygpath && [[ $TERM == emacs ]] ; then
  # use cygpath so Emacs dirtrack mode can track it
  PROMPT='%U$(mname_prompt) (%F{yellow}%{$(cygpath -m "`pwd`")%}%f $(vcs_info_wrapper)) %@ %B%!=>%b%u
%# %B'
  PROMPT2='%U$(mname_prompt)%u %U%B%UMORE:%u%b %B=>%b '
else
  PROMPT='%U$(wsl_prompt)$(mname_prompt) %F{cyan}$(gcproject_prompt)%f (%F{yellow}%~%f $(vcs_info_wrapper)) %@ %B%!=>%b%u
%# %B'
  PROMPT2='%U$(mname_prompt)%u %U%B%UMORE:%u%b %B=>%b '
fi
if has_command echotc ; then
  POSTEDIT=`echotc me`	# turn off all attributes
fi
RPROMPT=

# Modern replacements for find, ls, etc.:
# - fzf: fuzzy-finder
# - eza: ls with tree, git integration
# - delta: pretty diff viewer
# - bat: syntax-highlighted "cat"
# - fd: find replacement
# - ripgrep: grep/find
[[ -n "$ZSH_VERSION" && -f ~/.fzf.zsh ]] && source ~/.fzf.zsh # enable completions with **[TAB] and CTRL-T
# If we have both fd and fzf, use fd as source for fzf default:
if has_command fd && has_command fzf; then
    export FZF_DEFAULT_COMMAND='fd --type f'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# For bash, nothing fancy but better than default:
if [[ -n "$BASH_VERSION" ]]; then
  PS1='\u@\h [\W] % '
fi

# Only set chpwd (or prompt) to echo to xterm title bar if on an xterm
if [[ -n "$ZSH_VERSION" ]]; then
  chpwd () {
      [[ $TERM = xterm* ]] && print -Pn "]2;%m (%l:$WSL2_OSNAME): %~" > /dev/tty
  }
  if [[ $TERM = xterm* ]]; then
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
timediff1 "before starting ssh-agent"
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
       #echo "No running ssh agent; starting new one with $SSH_AUTH_SOCK"
       rm -f "$SSH_AUTH_SOCK"
       eval $(ssh-agent -a $SSH_AUTH_SOCK) >& /dev/null
   fi
fi
timediff1 "after starting ssh-agent"

if [[ -f ~/.authinfo ]]; then
   export OPENAI_API_KEY=$(awk '/openai/ {print $4}' ~/.authinfo)
fi

# Simple ChatGPT command-line assistant for zsh
# (There's a plugin for this at https://github.com/antonjs/zsh-gpt/blob/main/zsh-gpt.plugin.zsh
# but it's so simple, might as well just inline it here.)
if [[ -n "$ZSH_VERSION" ]]; then
   gpt() {
     if [[ ! $+commands[curl] ]]; then echo "Curl must be installed."; return 1; fi
     if [[ ! $+commands[jq] ]]; then echo "Jq must be installed."; return 1; fi
     if [[ ! -v OPENAI_API_KEY ]]; then echo "Must set OPENAI_API_KEY to your API key"; return 1; fi

     curl https://api.openai.com/v1/chat/completions -s \
       -H "Content-Type: application/json" \
       -H "Authorization: Bearer $OPENAI_API_KEY" \
       -d '{
       "model": "gpt-4o",
       "messages": [{"role": "system", "content": "you''re an in-line zsh assistant running on linux. Your task is to answer the questions without any commentation at all, providing only the code to run on terminal. You can assume that the user understands that they need to fill in placeholders like <PORT>. You''re not allowed to explain anything and you''re not a chatbot. You only provide shell commands or code. Keep the responses to one-liner answers as much as possible. Do not decorate the answer with tickmarks"}, {"role": "user", "content": "'"$*"'"}]
     }' | jq -r '.choices[0].message.content'
   }
fi

# Setup for zsh-autoenv. Set these before loading it.
# See https://github.com/Tarrasch/zsh-autoenv
# Use the same file for leave events as enter. (See $autoenv_event)
AUTOENV_HANDLE_LEAVE=1
AUTOENV_FILE_LEAVE=.autoenv.zsh

########################################################################
# Enable completion (e.g. git, cd, etc.)
########################################################################

# Zplug plugin manager
# See https://github.com/zplug/zplug
if [[ -n $ZSH_VERSION && -f ~/.zplug/init.zsh ]]; then
    source ~/.zplug/init.zsh

    zplug 'zplug/zplug', hook-build:'zplug --self-manage'
    zplug "Tarrasch/zsh-autoenv" # .autoenv.zsh files for dir enter/leave events

    zplug load        # load all above plugins
    # Note: if you get "no job control in this shell" do `rm ~/.zplug/log/job.lock`
fi

if [[ -n "$ZSH_VERSION" ]]; then
    DISABLE_COMPAUDIT=true
    mkdir -p ~/.zsh/cache
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zsh/cache
    autoload -Uz compinit
    compinit -u -C -d ~/.zsh/cache/zcompdump
fi

########################################################################
# Completion plugins
########################################################################

# if [[ -n "$ZSH_VERSION" ]]; then
#     timediff1 "before zsh antigen setup"
#     if [[ ! -f ~/antigen.zsh ]]; then
#         curl -L git.io/antigen > ~/antigen.zsh
#     fi
#     source ~/antigen.zsh
#     antigen bundle git >& /dev/null
#     antigen bundle zsh-users/zsh-completions >& /dev/null
#     antigen apply
#     timediff1 "after zsh antigen setup"
# fi

# I don't care that some dirs are other-writable, and I care about my eyes
# use light-blue (94) for other-writable dirs
export LS_COLORS=$(echo -n "$LS_COLORS"|sed 's/ow=[0-9]*;[0-9]*/ow=94;40/g')
# brighter blue for dates (see https://en.wikipedia.org/wiki/ANSI_escape_code)
export EXA_COLORS='da=38;5;63'

# Direnv -- directory-local .env files
# https://github.com/direnv/direnv
if has_command direnv; then
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(direnv hook zsh)"
    else
        eval "$(direnv hook bash)"
    fi
fi

########################################################################
# Python virtualenvs: always use `uv` as of 2024.
# Poetry, conda/miniconda etc. are old, buggy & too heavyweight
########################################################################

# Must be after adding `uv`'s path (i.e. `setpath_rust`, called from `maybe_setpath`)
# And after zplug setup.
if has_command uv; then
    # set up completions for `uv` and `uvx`
    if [ -n "$ZSH_VERSION" ]; then
      eval "$(uv generate-shell-completion zsh)"
      compdef _uv uv
    else
      eval "$(uv generate-shell-completion bash)"
    fi
fi

# Emacs eat: Emulate A Terminal -- load its simple shell integration for dir tracking
if [[ -n $ZSH_VERSION && -f ~/.config/emacs/elpaca/var/repos/eat/integration/zsh ]]; then
    source ~/.config/emacs/var/elpaca/repos/eat/integration/zsh
fi

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Local bashrc:
if [[ -f ~/Dotfiles/bashrc.local ]]; then
    source ~/Dotfiles/bashrc.local
fi
if [[ -f ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi

########################################################################

timediff1 "end"

if [[ $TIMEDIFF_ON -gt 0 && -n "$ZSH_VERSION" ]] ; then
    zprof
fi


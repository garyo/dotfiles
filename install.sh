#! /bin/bash

SCRIPTDIR=$(dirname $BASH_SOURCE)

cd "$SCRIPTDIR"

DOTFILES=(bashrc emacs emacs-orgmode gitconfig gitignore
	  hgrc profile pythonstartup ogl
          vimrc zshrc)

for f in "${DOTFILES[@]}"; do
    TARGET=~/."$f"
    if [ -e $TARGET -a ! -L $TARGET ]; then
        echo $TARGET already exists, not a symlink
    else
        ln -sf "Dotfiles/$f" "$TARGET"
        echo "$f" to "$TARGET"
    fi
done

# espanso
if [ -d ~/Library/Preferences ]; then # Mac
  TARGET=~/Library/Preferences/espanso
  mkdir -p $TARGET
  for f in espanso/*; do
    if [ -e $TARGET/user/$f -a ! -L $TARGET/user/$f ]; then
        echo $TARGET/user/$f already exists, not a symlink
    else
        ln -sf "$(pwd)/$f" "$TARGET/user/"
        echo "espanso/$f to $TARGET/user"
    fi
  done
elif [ -d ~/.config ]; then     # Linux
  TARGET=~/.config/espanso
  mkdir -p $TARGET
  for f in espanso/*; do
    if [ -e $TARGET/user/$f -a ! -L $TARGET/user/$f ]; then
        echo $TARGET/user/$f already exists, not a symlink
    else
        ln -sf "$(pwd)/$f" "$TARGET/user/"
        echo "espanso/$f to $TARGET/user"
    fi
  done
fi

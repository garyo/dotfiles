#! /bin/bash

SCRIPTDIR=$(dirname $BASH_SOURCE)

cd "$SCRIPTDIR"

DOTFILES=(bashrc emacs emacs-orgmode gitconfig gitignore
	  hgrc profile pythonstartup
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

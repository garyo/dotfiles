# Dotfiles for Gary Oberbrunner #

This is my dotfiles setup. Managed with [yadm](yadm.io). Everything except emacs config is in here.

# Usage

* Install [yadm](yadm.io) -- it's just a shell script, but it's in homebrew.
* `yadm clone https://github.com/garyo/dotfiles`

That's it! It will try to run the `bootstrap` file which installs some useful things on a new machine.

With `yadm`, `$HOME` is a git working dir. The corresponding bare repo is in `$HOME/.local/share/yadm/repo.git`. `yadm` is a thin front end around git, so most git commands work (including all git aliases!), and `yadm` always uses its git repo, so from anywhere `yadm status` will show you which dotfiles are out of date, and `yadm list` will show all tracked files.

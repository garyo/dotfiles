;; Dotfiles managed with yadm, so if I open e.g. ~/.bashrc, I don't want it
;; to use my entire home dir as the project dir. That would be *extremely* slow,
;; since e.g. LSP servers would try to manage all files in all of $HOME.
((nil . ((project-root . (expand-file-name "~/.local/share/yadm/repo.git")))))

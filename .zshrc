# .zshrc for Gary Oberbrunner, 2012

# Executed by zsh directly for interactive shells (login or not)
# Just run .bashrc

if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# bun completions
[ -s "/Users/garyo/.bun/_bun" ] && source "/Users/garyo/.bun/_bun"

# clipea: CLI command helper using ChatGPT
if python -c "import clipea" >& /dev/null; then
  clipea_zsh=$(dirname $(python3 -c "import clipea; print(clipea.__file__)"))/clipea.zsh
  alias '??'='source $clipea_zsh'
fi

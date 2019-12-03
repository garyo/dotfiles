# Powershell script to install symlinks to dotfiles
# Before running this script, run this in Powershell (as Admin):
#  Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force
# Then run the script:
#  install.ps1

# Elevate if not already admin:
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))

{
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
Break
}

# Files to symlink
$files = @("emacs", "bashrc", "emacs-orgmode", "hgrc", "gitconfig", "gitignore",
           "profile", "pythonstartup", "vimrc", "zshrc")
$dirs = @("..", "c:/msys64/home/garyo")
foreach ($d in $dirs) {
  echo "Installing into '$d'..."
  if (Test-Path $d) {
    foreach ($f in $files) {
      if (-not (Test-Path $d/.$f)) {
        New-Item -type SymbolicLink -path $d/.$f -value $f
      }
    }
  }
}

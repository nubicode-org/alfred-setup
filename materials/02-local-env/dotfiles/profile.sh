# shellcheck shell=bash
# A portable interactive profile. Source it from ~/.zshrc or ~/.bashrc:
#   [ -f ~/dotfiles/profile.sh ] && . ~/dotfiles/profile.sh
# Every optional block checks that its tool exists, so this is safe on a brand-new machine.

# What git, crontab -e and similar tools open. Set it once and you are never stuck in an unknown editor.
if command -v code >/dev/null 2>&1; then
  export EDITOR="code --wait"
else
  export EDITOR="nano"
fi
export VISUAL="$EDITOR"

# Add a directory to PATH only if it exists and is not there already.
path_add() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) if [ -d "$1" ]; then PATH="$PATH:$1"; fi ;;
  esac
}
path_add "$HOME/.local/bin"
path_add "$HOME/go/bin"
export PATH

# Aliases only exist in interactive shells. A script that calls "ll" fails, which is the point:
# scripts should spell out the command they mean.
alias ll='ls -lah'
alias gs='git status --short --branch'

if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
fi

# Load a local, uncommitted file for anything machine-specific (work proxies, private paths).
if [ -f "$HOME/.profile.local" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.profile.local"
fi

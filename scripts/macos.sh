#!/usr/bin/env bash
# Prepare a Mac for the Alfred Learning roadmap, with Homebrew.
# Safe to run more than once: anything already installed is skipped.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

NO_DOCKER=0

usage() {
  cat <<'EOF'
Usage: ./scripts/macos.sh [options]

Installs the tools the Alfred Learning courses use, with Homebrew.

Options:
  --dry-run      Show what would be installed and the exact commands, change nothing
  --yes, -y      Do not ask for confirmation
  --with-cloud   Also install the AWS CLI and Terraform (for the later cloud topics)
  --no-docker    Skip Docker Desktop (you use Colima, OrbStack or another runtime)
  --help         Show this help

Environment:
  NODE_MAJOR     Install this Node.js major version instead of the current LTS
EOF
}

while [ $# -gt 0 ]; do
  if ! parse_common_flag "$1"; then
    case "$1" in
      --no-docker) NO_DOCKER=1 ;;
      --help | -h) usage; exit 0 ;;
      *) usage >&2; die "Unknown option: $1" ;;
    esac
  fi
  shift
done

[ "$(uname -s)" = "Darwin" ] || die "This script is for macOS. On Linux or inside WSL run ./scripts/linux.sh."

ARCH=$(cpu_arch)
BREW_PREFIX=$([ "$ARCH" = arm64 ] && echo /opt/homebrew || echo /usr/local)
BREW_ON_PATH=0
have brew && BREW_ON_PATH=1
if ! have brew && [ -x "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

# command|formula. A command already on PATH is skipped, wherever it came from.
FORMULAE="
git|git
gh|gh
jq|jq
go|go
kubectl|kubernetes-cli
kind|kind
helm|helm
yamllint|yamllint
actionlint|actionlint
shellcheck|shellcheck
pre-commit|pre-commit
gitleaks|gitleaks
trivy|trivy
"
CLOUD_FORMULAE="
aws|awscli
terraform|hashicorp/tap/terraform
"

python_ok() { have python3 && version_ge "$(python3 --version 2>&1 | first_version)" 3.10; }
vscode_present() { have code || [ -d "/Applications/Visual Studio Code.app" ]; }
docker_present() { have docker || [ -d /Applications/Docker.app ]; }

missing=''
list=$FORMULAE
[ "$WITH_CLOUD" -eq 1 ] && list="$list$CLOUD_FORMULAE"
for row in $list; do
  have "${row%%|*}" || missing="$missing ${row#*|}"
done
python_ok || missing="$missing python"

step "Alfred Learning setup for macOS $(sw_vers -productVersion) ($ARCH)"
if have brew; then have_it "Homebrew (already installed)"; else info "install Homebrew from brew.sh (it asks for your password and may install the Xcode Command Line Tools)"; fi
if [ -n "$missing" ]; then info "brew install:$missing"; else have_it "command-line tools (already installed)"; fi
if have node; then have_it "Node.js (already installed: $(node --version))"; else info "install Node.js LTS and npm"; fi
if vscode_present; then have_it "VS Code (already installed)"; else info "install VS Code (brew cask)"; fi
if [ "$NO_DOCKER" -eq 1 ]; then have_it "Docker (--no-docker)"
elif docker_present; then have_it "Docker (already installed)"
else info "install Docker Desktop (brew cask; free for personal use and small businesses, see docs/macos.md)"; fi
info "install the recommended VS Code extensions (any already present are skipped)"
info "curl, dig, nc, traceroute, openssl and ssh ship with macOS and are not installed."
info "Nothing here asks for an account or a token. Homebrew and casks may ask for your Mac password."
confirm

step "Homebrew"
if have brew; then
  have_it "brew $(brew --version | first_version)"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    info "would run the official installer from https://brew.sh"
  else
    [ "$ASSUME_YES" -eq 1 ] && export NONINTERACTIVE=1
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi
fi
if [ "$ARCH" = arm64 ] && [ "$BREW_ON_PATH" -eq 0 ]; then
  # Apple silicon keeps Homebrew outside the default PATH; this is the line brew.sh asks you to add.
  ensure_profile_line "$HOME/.zprofile" "eval \"\$($BREW_PREFIX/bin/brew shellenv)\""
  case "${SHELL:-}" in
    */bash) ensure_profile_line "$HOME/.bash_profile" "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" ;;
  esac
fi

step "Command-line tools"
if [ -n "$missing" ]; then
  case "$missing" in *hashicorp/tap/*) run brew tap hashicorp/tap ;; esac
  # shellcheck disable=SC2086
  run brew install $missing
  added "brew install:$missing"
else
  have_it "all present"
fi

step "Node.js LTS"
if have node; then
  have_it "node $(node --version | first_version)"
else
  major=$(node_lts_major)
  current=$(brew info --json=v1 node 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null | cut -d. -f1 || true)
  if [ "$current" = "$major" ]; then
    run brew install node
  else
    # Homebrew's plain "node" follows the newest release; the versioned formula is the LTS line.
    run brew install "node@$major"
    run brew link --overwrite --force "node@$major"
  fi
fi

step "VS Code"
if vscode_present; then have_it "VS Code"; else run brew install --cask visual-studio-code; fi
if ! have code && [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi
install_vscode_extensions

step "Docker"
if [ "$NO_DOCKER" -eq 1 ]; then
  have_it "Docker (--no-docker)"
elif docker_present; then
  have_it "Docker"
else
  if brew info --cask docker-desktop >/dev/null 2>&1; then cask=docker-desktop; else cask=docker; fi
  run brew install --cask "$cask"
  info "Open Docker from Applications once and accept its terms; the docker command works after that."
fi

if [ "$DRY_RUN" -eq 1 ]; then
  step "Dry run finished. Nothing was changed."
  exit 0
fi
print_next_steps ''

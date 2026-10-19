# shellcheck shell=bash disable=SC2034  # the flag variables are read by the scripts that source this file
# Helpers shared by macos.sh, linux.sh and verify.sh. Sourced, never run on its own.

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_RED=$'\033[31m' C_RESET=$'\033[0m'
else
  C_BOLD='' C_DIM='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

DRY_RUN=0
ASSUME_YES=0
WITH_CLOUD=0

step() { printf '\n%s==> %s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
info() { printf '    %s\n' "$*"; }
have_it() { printf '    %sskip%s  %s\n' "$C_DIM" "$C_RESET" "$*"; }
added() { if [ "$DRY_RUN" -eq 0 ]; then printf '    %sdone%s  %s\n' "$C_GREEN" "$C_RESET" "$*"; fi; }
warn() { printf '    %swarn%s  %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() { printf '\n%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Retries every kind of failure, not only timeouts: a dropped connection on a slow or shared
# network is the usual reason a download fails, and trying again is the usual fix.
fetch() { curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 20 "$@"; }

# Every change the scripts make goes through run, so --dry-run shows the exact commands.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    %swould run:%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  printf '    %s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
  "$@"
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then run "$@"; else run sudo "$@"; fi
}

write_root_file() {
  local path=$1 content=$2
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    %swould write:%s %s\n' "$C_DIM" "$C_RESET" "$path"
    return 0
  fi
  printf '    %s$ write %s%s\n' "$C_DIM" "$path" "$C_RESET"
  if [ "$(id -u)" -eq 0 ]; then
    printf '%s\n' "$content" >"$path"
  else
    printf '%s\n' "$content" | sudo tee "$path" >/dev/null
  fi
}

# Appends a line to a shell profile once. Lines are matched exactly, so a re-run adds nothing.
ensure_profile_line() {
  local file=$1 line=$2
  if [ -f "$file" ] && grep -Fqx -- "$line" "$file"; then
    have_it "$file already has: $line"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    %swould add to %s:%s %s\n' "$C_DIM" "$file" "$C_RESET" "$line"
    return 0
  fi
  printf '\n# Added by alfred-setup\n%s\n' "$line" >>"$file"
  added "added to $file: $line"
}

confirm() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ -t 0 ] || die "There is no terminal to ask for confirmation. Re-run with --yes to proceed without asking."
  printf '\nProceed? [y/N] '
  local answer
  read -r answer
  case "$answer" in
    y | Y | yes | YES) return 0 ;;
    *) printf 'Nothing was changed.\n'; exit 0 ;;
  esac
}

parse_common_flag() {
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes | -y) ASSUME_YES=1 ;;
    --with-cloud) WITH_CLOUD=1 ;;
    *) return 1 ;;
  esac
}

cpu_arch() {
  case "$(uname -m)" in
    x86_64 | amd64) echo amd64 ;;
    aarch64 | arm64) echo arm64 ;;
    *) die "Unsupported CPU architecture: $(uname -m). The scripts support x86_64 and arm64." ;;
  esac
}

first_version() {
  grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1
}

# True when dotted version $1 is at least $2.
version_ge() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    n = split(a, x, "."); m = split(b, y, "."); k = (n > m ? n : m)
    for (i = 1; i <= k; i++) {
      if ((x[i] + 0) > (y[i] + 0)) exit 0
      if ((x[i] + 0) < (y[i] + 0)) exit 1
    }
    exit 0
  }'
}

sha256_of() {
  if have sha256sum; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}

# Checksums catch a broken or tampered download in transit. They come from the same
# publisher as the file, so they are not a substitute for trusting that publisher.
download_verified() {
  local url=$1 expected=$2 dest=$3 actual
  fetch -o "$dest" "$url" || die "Download failed: $url"
  actual=$(sha256_of "$dest")
  [ "$actual" = "$expected" ] || die "Checksum mismatch for $url (expected $expected, got $actual)"
}

# The tag of a project's latest GitHub release, e.g. v0.30.0. Unauthenticated, so no token is needed.
github_latest_tag() {
  local json tag
  if [ "$DRY_RUN" -eq 1 ]; then printf '<latest>\n'; return 0; fi
  json=$(fetch -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/$1/releases/latest" || true)
  tag=$(printf '%s' "$json" | grep -Eo '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n 1 | sed -E 's/.*"([^"]+)"$/\1/')
  [ -n "$tag" ] || die "Could not look up the latest release of $1 (GitHub may be rate limiting; wait an hour or try again)."
  printf '%s\n' "$tag"
}

# The major version of the current Node.js LTS line, e.g. 24. NODE_MAJOR overrides it.
node_lts_major() {
  if [ -n "${NODE_MAJOR:-}" ]; then
    printf '%s\n' "$NODE_MAJOR"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then printf '<lts>\n'; return 0; fi
  local index major
  index=$(fetch https://nodejs.org/dist/index.json || true)
  major=$(printf '%s' "$index" | tr '{' '\n' | grep -E '"lts":"[^"]' | head -n 1 |
    sed -nE 's/.*"version":"v([0-9]+)\..*/\1/p')
  [ -n "$major" ] || die "Could not look up the current Node.js LTS version. Set NODE_MAJOR (for example NODE_MAJOR=24) and re-run."
  printf '%s\n' "$major"
}

# VS Code extensions the courses use. The same list is in .vscode/extensions.json.
VSCODE_EXTENSIONS="
editorconfig.editorconfig
redhat.vscode-yaml
ms-python.python
golang.go
timonwong.shellcheck
ms-azuretools.vscode-docker
ms-kubernetes-tools.vscode-kubernetes-tools
github.vscode-github-actions
"

install_vscode_extensions() {
  if ! have code; then
    warn "VS Code's 'code' command is not on PATH yet, so extensions were not installed. Open a new terminal and re-run this script, or see docs/vscode.md."
    return 0
  fi
  local installed ext
  installed=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
  for ext in $VSCODE_EXTENSIONS; do
    if printf '%s\n' "$installed" | grep -Fqx "$ext"; then
      have_it "VS Code extension $ext"
    else
      run code --install-extension "$ext" --force && added "VS Code extension $ext"
    fi
  done
}

print_next_steps() {
  step "Next steps"
  info "1. Open a new terminal so PATH changes take effect$1."
  info "2. Set your Git identity and create an SSH key for GitHub: docs/git-and-ssh.md"
  info "3. Check everything: ./scripts/verify.sh"
}

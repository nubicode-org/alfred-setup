#!/usr/bin/env bash
# Check every tool the Alfred Learning courses use and print a pass/fail table with versions.
# Changes nothing. Exits 1 if anything a course needs is missing.
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

OFFLINE=0
for arg in "$@"; do
  case "$arg" in
    --offline) OFFLINE=1 ;;
    --help | -h)
      printf 'Usage: ./scripts/verify.sh [--offline]\n\n  --offline  Skip the GitHub SSH check, which needs the network\n'
      exit 0
      ;;
    *) die "Unknown option: $arg" ;;
  esac
done

# command|tier|minimum version|where the courses use it
TOOLS="
bash|core||the terminal every course assumes
git|core|2.30|Git, and every course's practice files
gh|core||Git, CI/CD (pull requests from the terminal)
ssh|core||Local Env, Git (SSH keys for GitHub)
curl|core||Networking, Security Awareness, CI/CD
jq|core||CI/CD, reading JSON from APIs
openssl|core||Networking, Security Awareness (certificates)
code|core||VS Code, the editor the guides use
python3|course|3.10|Programming
go|course|1.22|Programming
node|course|20|CI/CD, Containers (sample apps)
npm|course||CI/CD, Containers
dig|course||Networking (DNS)
nc|course||Networking (ports)
traceroute|course||Networking (routes)
shellcheck|course||OS Concepts, Local Env (scripts)
docker|course||Containers, Security
kubectl|course||Kubernetes
kind|course||Kubernetes (a local cluster)
helm|course||Kubernetes
yamllint|course||CI/CD, Kubernetes
actionlint|course||CI/CD (GitHub Actions)
pre-commit|course||Git, CI/CD (hooks)
gitleaks|course||Git, Security (secret scanning)
trivy|course||Security, Containers (image scanning)
aws|later||Cloud (AWS), optional for now
terraform|later||Infrastructure as Code, optional for now
"

# Places installers put tools that a terminal opened before the install has not picked up.
EXTRA_PATHS=("$HOME/.local/bin" /usr/local/go/bin "$HOME/go/bin" /opt/homebrew/bin /usr/local/bin
  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin")

version_of() {
  case "$1" in
    go) go version ;;
    ssh) ssh -V 2>&1 ;;
    kubectl) kubectl version --client 2>/dev/null ;;
    helm) helm version --short ;;
    kind) kind version ;;
    gitleaks) gitleaks version ;;
    shellcheck) shellcheck --version | sed -n 2p ;;
    openssl) openssl version ;;
    dig) dig -v 2>&1 ;;
    actionlint) actionlint -version ;;
    terraform) terraform version ;;
    aws) aws --version 2>&1 ;;
    nc | traceroute) return 0 ;;
    *) "$1" --version 2>&1 ;;
  esac 2>/dev/null | head -n 1 | first_version
}

FAILS=0
WARNS=0
HINTS=''

row() {
  local name=$1 tier=$2 status=$3 detail=$4 color
  case "$status" in
    PASS) color=$C_GREEN ;;
    FAIL) color=$C_RED ;;
    WARN) color=$C_YELLOW ;;
    *) color=$C_DIM ;;
  esac
  printf '  %-15s %-7s %s%-5s%s %s\n' "$name" "$tier" "$color" "$status" "$C_RESET" "$detail"
}

hint() { HINTS="$HINTS
  - $1"; }

guide_for_os() {
  case "$(uname -s)" in
    Darwin) echo docs/macos.md ;;
    *) if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then echo docs/windows.md; else echo docs/linux.md; fi ;;
  esac
}
GUIDE=$(guide_for_os)

printf '\n%sAlfred Learning setup check%s  (%s, %s)\n\n' "$C_BOLD" "$C_RESET" "$(uname -s)" "$(uname -m)"
printf '  %-15s %-7s %-5s %s\n' CHECK TIER STATE "VERSION / DETAIL"
printf '  %-15s %-7s %-5s %s\n' --------------- ------- ----- ----------------

while IFS='|' read -r cmd tier min purpose <&3; do
  [ -n "$cmd" ] || continue
  if have "$cmd"; then
    version=$(version_of "$cmd")
    if [ -n "$min" ] && [ -n "$version" ] && ! version_ge "$version" "$min"; then
      row "$cmd" "$tier" WARN "$version (the courses expect $min or newer)"
      WARNS=$((WARNS + 1))
      hint "$cmd $version is older than $min. Upgrade it: $GUIDE"
    elif [ "$cmd" = node ] && [ -n "$version" ] && [ $(( ${version%%.*} % 2 )) -eq 1 ]; then
      row "$cmd" "$tier" WARN "$version (an odd major is not an LTS release)"
      WARNS=$((WARNS + 1))
      hint "Node.js ${version%%.*} is a short-lived release. The courses assume an even-numbered LTS line."
    else
      row "$cmd" "$tier" PASS "${version:-installed}"
    fi
    continue
  fi
  found=''
  for d in "${EXTRA_PATHS[@]}"; do
    if [ -x "$d/$cmd" ]; then found="$d/$cmd"; break; fi
  done
  if [ -n "$found" ]; then
    row "$cmd" "$tier" WARN "installed at $found but not on PATH"
    WARNS=$((WARNS + 1))
    hint "$cmd is installed but this terminal cannot see it. Open a new terminal; if it persists, see 'PATH' in README.md."
  elif [ "$tier" = later ]; then
    row "$cmd" "$tier" '--' "not installed ($purpose)"
  else
    row "$cmd" "$tier" FAIL "missing ($purpose)"
    FAILS=$((FAILS + 1))
    hint "$cmd is missing. Re-run the setup script for your system, or install it by hand: $GUIDE"
  fi
done 3<<<"$TOOLS"

printf '\n'

if have docker; then
  if docker compose version >/dev/null 2>&1; then
    row "docker compose" course PASS "$(docker compose version 2>/dev/null | first_version)"
  else
    row "docker compose" course FAIL "the compose plugin is missing"
    FAILS=$((FAILS + 1))
    hint "Install the Docker compose plugin (it ships with Docker Desktop; on Linux: docker-compose-plugin)."
  fi
  if docker_err=$(docker info 2>&1 >/dev/null); then
    row "docker engine" course PASS "running"
  else
    row "docker engine" course WARN "installed but not reachable"
    WARNS=$((WARNS + 1))
    case "$docker_err" in
      *"permission denied"*) hint "Docker refused your user. Log out and back in so the docker group applies." ;;
      *) hint "Start Docker (open Docker Desktop, or: sudo systemctl start docker), then run this again." ;;
    esac
  fi
fi

if have git; then
  git_name=$(git config --global user.name || true)
  git_email=$(git config --global user.email || true)
  if [ -n "$git_name" ] && [ -n "$git_email" ]; then
    row "git identity" setup PASS "$git_name <$git_email>"
  else
    row "git identity" setup FAIL "user.name or user.email is not set"
    FAILS=$((FAILS + 1))
    hint "Tell Git who you are before your first commit: docs/git-and-ssh.md, step 1."
  fi
fi

key=''
for k in id_ed25519 id_ecdsa id_rsa; do
  [ -f "$HOME/.ssh/$k.pub" ] && key="$HOME/.ssh/$k.pub" && break
done
if [ -n "$key" ]; then
  row "ssh key" setup PASS "$key"
else
  row "ssh key" setup WARN "no key in ~/.ssh yet"
  WARNS=$((WARNS + 1))
  hint "Create an SSH key for GitHub: docs/git-and-ssh.md, step 2."
fi

if [ "$OFFLINE" -eq 1 ]; then
  row "github ssh" setup '--' "skipped (--offline)"
elif ! ssh-keygen -F github.com >/dev/null 2>&1; then
  row "github ssh" setup WARN "not connected yet"
  WARNS=$((WARNS + 1))
  hint "Add your key to GitHub and run 'ssh -T git@github.com' once: docs/git-and-ssh.md, step 3."
else
  gh_reply=$(ssh -T -o BatchMode=yes -o ConnectTimeout=8 git@github.com 2>&1 || true)
  case "$gh_reply" in
    *"successfully authenticated"*)
      row "github ssh" setup PASS "$(printf '%s' "$gh_reply" | sed -nE 's/^Hi ([^!]+)!.*/signed in as \1/p')"
      ;;
    *)
      row "github ssh" setup WARN "GitHub did not accept your key"
      WARNS=$((WARNS + 1))
      hint "GitHub answered: $(printf '%s' "$gh_reply" | head -n 1 | sed 's/[.]*$//'). See docs/git-and-ssh.md, 'Troubleshooting'."
      ;;
  esac
fi

printf '\n'
if [ "$FAILS" -eq 0 ] && [ "$WARNS" -eq 0 ]; then
  printf '%sAll set.%s Your computer is ready for the roadmap.\n' "$C_GREEN" "$C_RESET"
elif [ "$FAILS" -eq 0 ]; then
  printf '%sReady, with %d warning(s).%s You can start the roadmap; fix these before the course that needs them:%s\n' \
    "$C_YELLOW" "$WARNS" "$C_RESET" "$HINTS"
else
  printf '%s%d check(s) failed%s, %d warning(s). What to do:%s\n' "$C_RED" "$FAILS" "$C_RESET" "$WARNS" "$HINTS"
fi
printf '\nTiers: core = from course 1, course = needed by a specific course, later = the cloud topics, setup = your accounts.\n'

[ "$FAILS" -eq 0 ]

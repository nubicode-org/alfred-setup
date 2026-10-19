#!/usr/bin/env bash
# Prepare an Ubuntu or Debian machine (or Ubuntu inside WSL2) for the Alfred Learning roadmap.
# Safe to run more than once: anything already installed is skipped.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

NO_DOCKER=0
DOCKER_ENGINE=0
NO_VSCODE=0
DOCKER_INSTALLED=0

usage() {
  cat <<'EOF'
Usage: ./scripts/linux.sh [options]

Installs the tools the Alfred Learning courses use on Ubuntu or Debian (apt).
Inside WSL2 it installs the Linux side; Docker and VS Code come from Windows.

Options:
  --dry-run        Show what would be installed and the exact commands, change nothing
  --yes, -y        Do not ask for confirmation
  --with-cloud     Also install the AWS CLI and Terraform (for the later cloud topics)
  --no-docker      Skip Docker (you use Docker Desktop, Podman or another runtime)
  --docker-engine  Inside WSL2, install Docker Engine in Ubuntu instead of using Docker Desktop
  --no-vscode      Skip VS Code (a server or a machine without a desktop)
  --help           Show this help

Environment:
  NODE_MAJOR       Install this Node.js major version instead of the current LTS
EOF
}

while [ $# -gt 0 ]; do
  if ! parse_common_flag "$1"; then
    case "$1" in
      --no-docker) NO_DOCKER=1 ;;
      --docker-engine) DOCKER_ENGINE=1 ;;
      --no-vscode) NO_VSCODE=1 ;;
      --help | -h) usage; exit 0 ;;
      *) usage >&2; die "Unknown option: $1" ;;
    esac
  fi
  shift
done

[ "$(uname -s)" = "Linux" ] || die "This script is for Linux. On a Mac run ./scripts/macos.sh; on Windows run scripts/windows.ps1."
[ -r /etc/os-release ] || die "Cannot read /etc/os-release to identify this distribution."
# shellcheck disable=SC1091
. /etc/os-release

DISTRO=''
case " ${ID:-} ${ID_LIKE:-} " in
  *" ubuntu "*) DISTRO=ubuntu ;;
  *" debian "*) DISTRO=debian ;;
esac
if [ -z "$DISTRO" ]; then
  case " ${ID:-} ${ID_LIKE:-} " in
    *" fedora "* | *" rhel "*) die "This script uses apt. On Fedora, follow the dnf commands in docs/linux.md (section 'Fedora')." ;;
    *) die "Unsupported distribution '${ID:-unknown}'. The script supports Ubuntu and Debian; docs/linux.md lists every tool if you install by hand." ;;
  esac
fi
# Derivatives such as Linux Mint report their own codename; Docker and HashiCorp publish for Ubuntu's.
CODENAME=${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}
[ -n "$CODENAME" ] || die "Cannot tell which release of $DISTRO this is (no VERSION_CODENAME in /etc/os-release)."

IN_WSL=0
if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then IN_WSL=1; fi
ARCH=$(cpu_arch)
DEB_ARCH=$(dpkg --print-architecture)

if [ "$(id -u)" -ne 0 ] && ! have sudo; then
  die "sudo is not installed. Install it as root (apt-get install sudo) and add your user to the sudo group."
fi

export PATH="$PATH:$HOME/.local/bin"

APT_PACKAGES="ca-certificates curl gnupg git jq dnsutils netcat-openbsd traceroute openssl openssh-client
python3 python3-pip python3-venv pipx yamllint shellcheck unzip make"

pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

want_docker() {
  [ "$NO_DOCKER" -eq 0 ] || return 1
  have docker && return 1
  [ "$IN_WSL" -eq 0 ] || [ "$DOCKER_ENGINE" -eq 1 ]
}
want_vscode() { [ "$NO_VSCODE" -eq 0 ] && [ "$IN_WSL" -eq 0 ] && ! have code; }

missing_apt=''
for p in $APT_PACKAGES; do pkg_installed "$p" || missing_apt="$missing_apt $p"; done

plan_line() { if have "$1"; then have_it "$2 (already installed)"; else info "install $2"; fi; }

step "Alfred Learning setup for ${PRETTY_NAME:-$DISTRO} ($ARCH)$([ "$IN_WSL" -eq 1 ] && printf ', inside WSL2')"
if [ -n "$missing_apt" ]; then info "apt packages:$missing_apt"; else have_it "base apt packages (already installed)"; fi
plan_line gh "GitHub CLI (gh), from GitHub's apt repository"
plan_line go "Go, the latest stable release from go.dev, into /usr/local/go"
plan_line node "Node.js LTS and npm, from the NodeSource apt repository"
plan_line kubectl "kubectl, from the Kubernetes apt repository (pkgs.k8s.io)"
plan_line kind "kind (Kubernetes in Docker), from its GitHub release"
plan_line helm "Helm, from get.helm.sh"
plan_line actionlint "actionlint (GitHub Actions linter), from its GitHub release"
plan_line gitleaks "gitleaks (secret scanner), from its GitHub release"
plan_line trivy "Trivy (vulnerability scanner), from Aqua Security's apt repository"
plan_line pre-commit "pre-commit, with pipx"
if want_docker; then
  info "install Docker Engine and the compose plugin, from Docker's apt repository, and add you to the docker group"
elif [ "$NO_DOCKER" -eq 1 ]; then
  have_it "Docker (--no-docker)"
elif have docker; then
  have_it "Docker (already installed)"
else
  info "Docker: not installed here. Inside WSL2 it comes from Docker Desktop on Windows (see docs/windows.md)"
fi
if want_vscode; then info "install VS Code, from Microsoft's apt repository"; fi
if have code; then info "install the recommended VS Code extensions (any already present are skipped)"; fi
if [ "$WITH_CLOUD" -eq 1 ]; then
  plan_line aws "AWS CLI v2 (optional, for the later cloud topics)"
  plan_line terraform "Terraform (optional), from HashiCorp's apt repository"
fi
info "Nothing here asks for an account, a token or a password other than sudo's."
confirm

KEYRINGS=/etc/apt/keyrings
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
apt_updated=0

apt_update() { as_root apt-get update -qq; apt_updated=1; }

apt_install() {
  [ "$apt_updated" -eq 1 ] || apt_update
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ||
    die "apt-get could not install: $*. The messages above say why; a network or DNS problem is the usual cause (see Troubleshooting in README.md). Run the script again once it is fixed."
}

# Adds a signed apt repository once. The key is stored per repository, never trusted globally.
add_apt_repo() {
  local name=$1 key_url=$2 line=$3 dearmor=${4:-yes}
  local key="$KEYRINGS/$name.gpg" list="/etc/apt/sources.list.d/$name.list"
  if [ -f "$list" ] && [ -f "$key" ]; then return 0; fi
  as_root install -m 0755 -d "$KEYRINGS"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "would add the $name apt key from $key_url"
  else
    fetch "$key_url" -o "$TMP/$name.key" || die "Could not download the $name signing key."
    if [ "$dearmor" = yes ]; then
      gpg --dearmor --yes -o "$TMP/$name.gpg" "$TMP/$name.key"
    else
      cp "$TMP/$name.key" "$TMP/$name.gpg"
    fi
    as_root install -m 0644 "$TMP/$name.gpg" "$key"
  fi
  write_root_file "$list" "deb [arch=$DEB_ARCH signed-by=$key] $line"
  apt_updated=0
}

# Installs a single binary from a GitHub release whose checksums file lists the archive.
install_release_binary() {
  local name=$1 url=$2 sums_url=$3 asset=$4 member=$5 sums expected
  if [ "$DRY_RUN" -eq 1 ]; then
    info "would download $url, check it against $sums_url, and install $name into /usr/local/bin"
    return 0
  fi
  sums=$(fetch "$sums_url") || die "Could not download the checksums: $sums_url"
  expected=$(printf '%s\n' "$sums" | awk -v f="$asset" 'NF == 1 || $2 == f || $2 == "*" f {print $1; exit}')
  [ -n "$expected" ] || die "No checksum for $asset in $sums_url"
  download_verified "$url" "$expected" "$TMP/$asset"
  case "$asset" in
    *.tar.gz) tar -xzf "$TMP/$asset" -C "$TMP" "$member"; as_root install -m 0755 "$TMP/$member" "/usr/local/bin/$name" ;;
    *) as_root install -m 0755 "$TMP/$asset" "/usr/local/bin/$name" ;;
  esac
  added "$name $({ "/usr/local/bin/$name" version || "/usr/local/bin/$name" -version; } 2>/dev/null | first_version)"
}

step "Base packages"
if [ -n "$missing_apt" ]; then
  # shellcheck disable=SC2086
  apt_install $missing_apt
  added "apt packages:$missing_apt"
else
  have_it "base packages"
fi

step "GitHub CLI"
if have gh; then have_it "gh $(gh --version | first_version)"; else
  add_apt_repo githubcli https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "https://cli.github.com/packages stable main" no
  apt_install gh
fi

step "Go"
if have go; then
  have_it "go $(go version | first_version)"
elif [ -x /usr/local/go/bin/go ]; then
  have_it "Go is in /usr/local/go but not on PATH; linking it into /usr/local/bin"
  as_root ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/bin/
else
  if [ "$DRY_RUN" -eq 1 ]; then
    info "would download the latest stable Go for linux-$ARCH from go.dev, check its SHA-256, and unpack it into /usr/local/go"
  else
    go_json=$(fetch 'https://go.dev/dl/?mode=json')
    go_file=$(printf '%s' "$go_json" | jq -r --arg a "$ARCH" \
      '[.[] | select(.stable)][0].files[] | select(.os == "linux" and .arch == $a and .kind == "archive") | .filename')
    go_sha=$(printf '%s' "$go_json" | jq -r --arg f "$go_file" '.[].files[] | select(.filename == $f) | .sha256' | head -n 1)
    download_verified "https://go.dev/dl/$go_file" "$go_sha" "$TMP/$go_file"
    as_root rm -rf /usr/local/go
    as_root tar -C /usr/local -xzf "$TMP/$go_file"
    added "$go_file"
  fi
  as_root ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/bin/
fi

step "Node.js LTS"
if have node; then have_it "node $(node --version | first_version)"; else
  major=$(node_lts_major)
  info "current LTS line: Node.js $major"
  add_apt_repo nodesource https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    "https://deb.nodesource.com/node_$major.x nodistro main"
  apt_install nodejs
fi

step "Docker"
if want_docker; then
  docker_os=$DISTRO
  add_apt_repo docker "https://download.docker.com/linux/$docker_os/gpg" \
    "https://download.docker.com/linux/$docker_os $CODENAME stable"
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  DOCKER_INSTALLED=1
  if [ "$(id -u)" -ne 0 ]; then
    as_root usermod -aG docker "$(id -un)"
    info "You were added to the docker group. It takes effect after you log out and back in."
  fi
  if [ "$IN_WSL" -eq 1 ] && ! [ -d /run/systemd/system ]; then
    warn "systemd is off in this WSL distribution, so Docker will not start by itself. See docs/windows.md, 'Docker Engine inside WSL'."
  fi
elif [ "$NO_DOCKER" -eq 1 ]; then
  have_it "Docker (--no-docker)"
elif have docker; then
  have_it "docker $(docker --version | first_version)"
else
  info "Not installed here. In Docker Desktop on Windows: Settings > Resources > WSL integration > turn on Ubuntu."
  info "Prefer Docker inside Ubuntu instead? Re-run with --docker-engine."
fi

step "Kubernetes tools"
if have kubectl; then have_it "kubectl $(kubectl version --client 2>/dev/null | first_version)"; else
  if [ "$DRY_RUN" -eq 1 ]; then k8s_minor='<stable>'; else
    k8s_minor=$(fetch https://dl.k8s.io/release/stable.txt | cut -d. -f1,2)
  fi
  add_apt_repo kubernetes "https://pkgs.k8s.io/core:/stable:/$k8s_minor/deb/Release.key" \
    "https://pkgs.k8s.io/core:/stable:/$k8s_minor/deb/ /"
  apt_install kubectl
fi
if have kind; then have_it "kind $(kind version | first_version)"; else
  tag=$(github_latest_tag kubernetes-sigs/kind)
  install_release_binary kind "https://github.com/kubernetes-sigs/kind/releases/download/$tag/kind-linux-$ARCH" \
    "https://github.com/kubernetes-sigs/kind/releases/download/$tag/kind-linux-$ARCH.sha256sum" "kind-linux-$ARCH" ''
fi
if have helm; then have_it "helm $(helm version --short | first_version)"; else
  tag=$(github_latest_tag helm/helm)
  install_release_binary helm "https://get.helm.sh/helm-$tag-linux-$ARCH.tar.gz" \
    "https://get.helm.sh/helm-$tag-linux-$ARCH.tar.gz.sha256sum" "helm-$tag-linux-$ARCH.tar.gz" "linux-$ARCH/helm"
fi

step "Linters and scanners"
if have actionlint; then have_it "actionlint $(actionlint -version | first_version)"; else
  tag=$(github_latest_tag rhysd/actionlint)
  v=${tag#v}
  install_release_binary actionlint "https://github.com/rhysd/actionlint/releases/download/$tag/actionlint_${v}_linux_$ARCH.tar.gz" \
    "https://github.com/rhysd/actionlint/releases/download/$tag/actionlint_${v}_checksums.txt" \
    "actionlint_${v}_linux_$ARCH.tar.gz" actionlint
fi
if have gitleaks; then have_it "gitleaks $(gitleaks version | first_version)"; else
  tag=$(github_latest_tag gitleaks/gitleaks)
  v=${tag#v}
  gl_arch=$([ "$ARCH" = amd64 ] && echo x64 || echo arm64)
  install_release_binary gitleaks "https://github.com/gitleaks/gitleaks/releases/download/$tag/gitleaks_${v}_linux_$gl_arch.tar.gz" \
    "https://github.com/gitleaks/gitleaks/releases/download/$tag/gitleaks_${v}_checksums.txt" \
    "gitleaks_${v}_linux_$gl_arch.tar.gz" gitleaks
fi
if have trivy; then have_it "trivy $(trivy --version | first_version)"; else
  add_apt_repo trivy https://aquasecurity.github.io/trivy-repo/deb/public.key \
    "https://aquasecurity.github.io/trivy-repo/deb generic main"
  apt_install trivy
fi
if have pre-commit; then have_it "pre-commit $(pre-commit --version | first_version)"; else
  run pipx install pre-commit
  run pipx ensurepath >/dev/null
fi

if want_vscode; then
  step "VS Code"
  add_apt_repo vscode https://packages.microsoft.com/keys/microsoft.asc \
    "https://packages.microsoft.com/repos/code stable main"
  apt_install code
fi
if have code; then
  step "VS Code extensions"
  if [ "$IN_WSL" -eq 1 ]; then info "These install into VS Code's WSL server, so they work on files inside Ubuntu."; fi
  install_vscode_extensions
fi

if [ "$WITH_CLOUD" -eq 1 ]; then
  step "Cloud tools (optional)"
  if have aws; then have_it "aws $(aws --version 2>&1 | first_version)"; else
    aws_zip="awscli-exe-linux-$(uname -m).zip"
    if [ "$DRY_RUN" -eq 1 ]; then
      info "would download https://awscli.amazonaws.com/$aws_zip and run its installer"
    else
      fetch -o "$TMP/$aws_zip" "https://awscli.amazonaws.com/$aws_zip"
      unzip -q "$TMP/$aws_zip" -d "$TMP"
      as_root "$TMP/aws/install"
    fi
  fi
  if have terraform; then have_it "terraform $(terraform version | first_version)"; else
    add_apt_repo hashicorp https://apt.releases.hashicorp.com/gpg \
      "https://apt.releases.hashicorp.com $CODENAME main"
    apt_install terraform
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  step "Dry run finished. Nothing was changed."
  exit 0
fi
if [ "$DOCKER_INSTALLED" -eq 1 ]; then
  print_next_steps ', and log out and back in so the docker group applies'
else
  print_next_steps ''
fi

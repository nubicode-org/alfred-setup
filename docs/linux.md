# Linux setup

The script supports **Ubuntu 22.04 or newer** and **Debian 12 or newer**, and distributions built on
them (Linux Mint, Pop!_OS, elementary). It also runs inside WSL2 on Windows; see
[windows.md](windows.md) first if that is you. For Fedora, see [the end of this page](#fedora).

About 20 to 40 minutes. You need a user that can use `sudo`, and about 8 GB free.

## The quick way

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/nubicode-org/alfred-setup.git ~/alfred-setup
cd ~/alfred-setup
./scripts/linux.sh --dry-run    # see exactly what it would do
./scripts/linux.sh
```

Options: `--with-cloud` adds the AWS CLI and Terraform; `--no-docker` skips Docker (you use Podman or
already have it); `--no-vscode` skips VS Code on a machine without a desktop.

When it finishes, **log out and back in** (so the `docker` group applies), then do
[Git identity and SSH](git-and-ssh.md) and run `./scripts/verify.sh`.

## Step by step, by hand

What the script runs. Every third-party repository is added the same way: its signing key goes in
`/etc/apt/keyrings/<name>.gpg`, and its `.list` file names that key with `signed-by=`, so the key is
trusted for that repository only.

### 1. Base packages

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git jq dnsutils netcat-openbsd traceroute \
  openssl openssh-client python3 python3-pip python3-venv pipx yamllint shellcheck unzip make
```

`dnsutils` provides `dig`; `netcat-openbsd` provides `nc`. Ubuntu 22.04 ships Python 3.10 and newer
releases ship newer, which is what the Programming course needs.

### 2. GitHub CLI

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/githubcli.list
sudo apt-get update && sudo apt-get install -y gh
```

### 3. Go

The `golang` apt package is usually several releases behind, so install from [go.dev](https://go.dev/dl/).
Pick the `linux-amd64` (or `linux-arm64`) archive and check its SHA-256 against the one on that page:

```bash
curl -fLO https://go.dev/dl/go1.XX.Y.linux-amd64.tar.gz
sha256sum go1.XX.Y.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.XX.Y.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/bin/
```

### 4. Node.js LTS

From [NodeSource](https://github.com/nodesource/distributions), for the current LTS line (an even
number, listed on [nodejs.org](https://nodejs.org)). The script looks it up; by hand, set it:

```bash
NODE_MAJOR=24
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update && sudo apt-get install -y nodejs
```

### 5. Docker Engine

From [Docker's repository](https://docs.docker.com/engine/install/ubuntu/), not the `docker.io` package,
so you get the current Engine and the `docker compose` plugin. Use `debian` instead of `ubuntu` in both
URLs on Debian:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"     # then log out and back in
```

Check: `docker run --rm hello-world`. Membership of the `docker` group is equivalent to root on that
machine: fine on your own laptop, not something to grant on a shared server.

### 6. Kubernetes: kubectl, kind and Helm

```bash
K8S=$(curl -fsSL https://dl.k8s.io/release/stable.txt | cut -d. -f1,2)    # e.g. v1.34
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$K8S/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/$K8S/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubectl
```

Each Kubernetes minor version has its own repository, so to move to a newer kubectl later, change the
version in that `.list` file.

[kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries) and
[Helm](https://helm.sh/docs/intro/install/) are single binaries. Download the release for your
architecture from each project's page, check it against the published `.sha256sum`, and
`sudo install -m 0755 <file> /usr/local/bin/<name>`. The script does exactly that.

### 7. Linters and scanners

- **actionlint** and **gitleaks**: single binaries from their GitHub release pages
  ([actionlint](https://github.com/rhysd/actionlint/releases), [gitleaks](https://github.com/gitleaks/gitleaks/releases)),
  checked against the release's `checksums.txt`.
- **Trivy**, from Aqua Security's repository:

  ```bash
  curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
  echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    | sudo tee /etc/apt/sources.list.d/trivy.list
  sudo apt-get update && sudo apt-get install -y trivy
  ```

- **pre-commit**, with pipx (which keeps Python tools out of the system Python):

  ```bash
  pipx install pre-commit
  pipx ensurepath      # adds ~/.local/bin to PATH; open a new terminal afterwards
  ```

### 8. VS Code

```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/vscode.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt-get update && sudo apt-get install -y code
```

Then the extensions in [vscode.md](vscode.md). Prefer the Snap or Flatpak? Either works.

### 9. Optional: cloud tools

- AWS CLI v2: `curl -fsSLo awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" && unzip -q awscliv2.zip && sudo ./aws/install`
- Terraform, from [HashiCorp's repository](https://developer.hashicorp.com/terraform/install):

  ```bash
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update && sudo apt-get install -y terraform
  ```

## Check it works

```bash
./scripts/verify.sh
kind create cluster --name alfred
kubectl get nodes
kind delete cluster --name alfred
```

## Fedora

The script is apt only. On Fedora 40 or newer, the same tools with `dnf`:

```bash
sudo dnf install -y git gh jq bind-utils nmap-ncat traceroute openssl openssh-clients \
  python3 python3-pip pipx yamllint ShellCheck golang nodejs npm unzip make
```

- Fedora's `golang` and `nodejs` packages are current enough for the courses (check that
  `node --version` is an even major; if not, use `sudo dnf module` or NodeSource's RPM repository).
- **Docker:** follow [Docker's Fedora instructions](https://docs.docker.com/engine/install/fedora/)
  (`dnf config-manager addrepo` then `dnf install docker-ce docker-compose-plugin`), then
  `sudo systemctl enable --now docker` and `sudo usermod -aG docker "$USER"`. Podman, which Fedora ships,
  runs most of the Containers course too (`podman` accepts the same commands), but kind needs extra
  setup with it.
- **kubectl:** the [Kubernetes RPM repository](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management).
- **kind, Helm, actionlint, gitleaks:** the same release binaries as step 6 and 7 above.
- **Trivy:** Aqua Security's [RPM repository](https://trivy.dev/latest/getting-started/installation/).
- **pre-commit:** `pipx install pre-commit && pipx ensurepath`.
- **VS Code:** Microsoft's [RPM repository](https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions).

Then run `./scripts/verify.sh`, which works on any distribution.

## Troubleshooting

**`E: Could not get lock /var/lib/dpkg/lock-frontend`.** Automatic updates are running. Wait a few
minutes; `ps aux | grep -i apt` shows when they have finished.

**`docker: permission denied while trying to connect to the Docker daemon socket`.** The group change
needs a new login. Log out and back in (closing the terminal is not enough), or restart.

**`NO_PUBKEY` or `The following signatures couldn't be verified`.** A repository key was not saved.
Remove that repository's two files (`/etc/apt/keyrings/<name>.gpg` and
`/etc/apt/sources.list.d/<name>.list`) and run the script again; it adds them fresh.

**A repository has no `Release` file for your codename.** A very new release of your distribution
may not be published by a vendor yet (most often Docker or HashiCorp). Remove that `.list` file, and
either wait a few weeks or use the previous release's codename in it.

**`pipx: command not found` or `pre-commit: command not found`.** Run `pipx ensurepath` and open a new
terminal.

**Linux Mint or another derivative installs the wrong Docker packages.** The script uses
`UBUNTU_CODENAME` from `/etc/os-release`. If your derivative does not set it, edit
`/etc/apt/sources.list.d/docker.list` to the Ubuntu codename your release is based on.

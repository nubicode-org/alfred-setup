# macOS setup

For macOS 13 (Ventura) or newer, on Apple silicon or Intel. Everything is installed with
[Homebrew](https://brew.sh), the package manager most Mac developers use. About 20 to 40 minutes.

You need an administrator account (the one you set up the Mac with usually is) and about 8 GB free.

## The quick way

1. Open **Terminal** (Applications > Utilities, or Cmd+Space and type "Terminal").
2. Get the kit. macOS asks to install the **Command Line Tools** the first time you run `git`; accept,
   wait for it to finish, and run the command again.

   ```bash
   git clone https://github.com/nubicode-org/alfred-setup.git ~/alfred-setup
   cd ~/alfred-setup
   ```

3. See what it would do, then do it:

   ```bash
   ./scripts/macos.sh --dry-run
   ./scripts/macos.sh
   ```

   Homebrew asks for your Mac password (nothing appears as you type; that is normal) and to press
   Return. Add `--with-cloud` for the AWS CLI and Terraform, or `--no-docker` if you use Colima or
   OrbStack instead of Docker Desktop.

4. Open **Docker** from Applications once, accept its terms, and wait until it says it is running.
5. Open a new Terminal window, then do [Git identity and SSH](git-and-ssh.md) and run
   `./scripts/verify.sh`.

## Step by step, by hand

What the script runs, in order. Useful if you want to understand each step or the script stopped.

### 1. Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On **Apple silicon** (M1 and later) Homebrew lives in `/opt/homebrew`, which is not on your `PATH`
yet. The installer prints two lines to fix that; the important one is:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Check: `brew --version`.

### 2. Command-line tools

```bash
brew install git gh jq python go kubernetes-cli kind helm yamllint actionlint shellcheck pre-commit gitleaks trivy
```

macOS already includes `curl`, `ssh`, `dig`, `nc`, `traceroute` and `openssl` (LibreSSL), which is
enough for the courses. Apple's Git, from the Command Line Tools, also works; Homebrew's is newer.

`python` gives you `python3`. The Python that comes with the Command Line Tools is 3.9, which is too
old for the Programming course; after this step `python3 --version` should say 3.12 or newer. If it
still says 3.9, open a new terminal (Homebrew's comes first on `PATH`).

### 3. Node.js LTS

The courses assume a long-term support (LTS) release, which always has an even major number. Find the
current one at [nodejs.org](https://nodejs.org), then:

```bash
brew install node@24
brew link --overwrite --force node@24
```

If the LTS line is also the newest release, plain `brew install node` is the same thing. Already use
`nvm`, `fnm` or `mise`? Keep it, and install the LTS with it instead.

### 4. VS Code

```bash
brew install --cask visual-studio-code
```

Then the extensions in [vscode.md](vscode.md).

### 5. Docker

```bash
brew install --cask docker-desktop
```

Open it from Applications and accept the terms. Check: `docker run --rm hello-world`.

**Licensing:** Docker Desktop is free for personal use, education, open source and small businesses
(under 250 employees and under US$10 million revenue). A larger employer needs a paid subscription;
ask before installing it on a work Mac. Free alternatives that the courses work with:
[Colima](https://github.com/abiosoft/colima) (`brew install colima docker docker-compose && colima start`)
or [OrbStack](https://orbstack.dev) (free for personal use).

### 6. Optional: cloud tools

```bash
brew install awscli
brew tap hashicorp/tap && brew install hashicorp/tap/terraform
```

Terraform comes from HashiCorp's own tap because Homebrew's main repository no longer carries it.

## Check it works

```bash
./scripts/verify.sh
kind create cluster --name alfred     # a Kubernetes cluster in Docker, about a minute
kubectl get nodes                     # one node, Ready
kind delete cluster --name alfred
```

## Troubleshooting

**`xcrun: error: invalid active developer path`.** The Command Line Tools are missing, often after a
macOS upgrade. Run `xcode-select --install`, then try again.

**`brew: command not found` after installing Homebrew.** The `brew shellenv` line is not in
`~/.zprofile`, or the terminal was opened before it was added. Add it (step 1) and open a new window.
If you use bash instead of zsh, the file is `~/.bash_profile`.

**`python3 --version` still says 3.9.** `/usr/bin` is ahead of Homebrew on your `PATH`. Run
`which -a python3`; Homebrew's (`/opt/homebrew/bin/python3`) should be first. Check `~/.zprofile` for
a `PATH` line that puts `/usr/bin` first.

**"Docker Desktop is damaged" or will not open.** Quit it, run `brew reinstall --cask docker-desktop`,
and open it again. If you replaced it with Colima, run `colima start` first.

**`kind create cluster` hangs or fails.** Docker needs at least 4 GB of memory for a cluster: Docker
Desktop > Settings > Resources. Then `kind delete cluster --name alfred` and try again.

**Homebrew says a directory is not writable.** Do not use `sudo brew`. Run `brew doctor`, which prints
the exact `chown` command to fix it.

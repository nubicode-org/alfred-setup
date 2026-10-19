# Alfred Learning setup kit

Get your computer ready for the [Alfred Learning](https://alfred.nubicode.com) DevOps and Cloud
roadmap before you start course 1. One script per system installs everything the ten courses use,
and a second script checks that it all works.

The courses run in your browser and can be finished without installing anything: their exercises
use a terminal built into the page. This kit is for doing the same work on a real machine, which is
what the job looks like. Set it up before you start, or come back when a course makes you want to try
something for real.

## Quick start

Pick your system. Each guide explains every step, so you can also follow it by hand.

| System | Guide | One command |
| --- | --- | --- |
| macOS 13 or newer | [docs/macos.md](docs/macos.md) | `./scripts/macos.sh` |
| Ubuntu or Debian | [docs/linux.md](docs/linux.md) | `./scripts/linux.sh` |
| Fedora | [docs/linux.md#fedora](docs/linux.md#fedora) | by hand, with `dnf` |
| Windows 10 (2004+) or 11 | [docs/windows.md](docs/windows.md) | `scripts\windows.ps1`, then `./scripts/linux.sh` inside Ubuntu |

Get the kit first. If Git is already installed:

```bash
git clone https://github.com/nubicode-org/alfred-setup.git
cd alfred-setup
```

If it is not, download the ZIP from the green **Code** button on GitHub and unzip it. The per-system
guide says where to put it.

Then run your system's script. Every script:

- **prints what it will install and asks first.** `--dry-run` shows the exact commands and changes nothing.
- **skips anything already installed**, so running it again is safe and only fills in what is missing.
- **never asks for an account, a token or an API key.** The only password it needs is your computer's
  own (`sudo` on Mac and Linux, an administrator window on Windows).

When it finishes, set up Git and your SSH key ([docs/git-and-ssh.md](docs/git-and-ssh.md)) and check
everything:

```bash
./scripts/verify.sh
```

## What gets installed, and why

Every tool below is used by at least one course. The **tier** says when you need it.

- **core**: from course 1. Every course assumes a terminal, an editor and Git.
- **course**: a specific course uses it. Missing one only matters when you reach that course.
- **later**: the cloud topics after the first ten courses. Not installed unless you ask (`--with-cloud`).

| Tool | Tier | What it is for | Courses |
| --- | --- | --- | --- |
| A terminal and shell (bash or zsh) | core | Where every command in the courses runs | All |
| Git | core | Version control; every practice file lives in a repository | Git, all |
| GitHub CLI (`gh`) | core | Pull requests and repositories from the terminal | Git, CI/CD |
| OpenSSH (`ssh`, `ssh-keygen`) | core | The key that lets you push to GitHub without a password | Local Env, Git |
| VS Code + [extensions](docs/vscode.md) | core | The editor the guides assume | All |
| curl, jq | core | Calling APIs and reading their JSON | Networking, CI/CD |
| OpenSSL | core | Reading certificates | Networking, Security Awareness |
| Python 3.10+ | course | Scripts for operators | Programming |
| Go | course | Small, single-file tools | Programming |
| Node.js LTS and npm | course | The sample apps the pipelines build | CI/CD, Containers |
| dig, nc, traceroute | course | DNS, ports and routes | Networking |
| ShellCheck | course | Catching shell-script mistakes before they run | OS Concepts, Local Env |
| Docker, with Compose | course | Building and running containers | Containers, Security |
| kubectl, kind, Helm | course | A real Kubernetes cluster on your laptop | Kubernetes |
| yamllint, actionlint | course | Catching YAML and GitHub Actions mistakes before CI does | CI/CD, Kubernetes |
| pre-commit, gitleaks | course | Hooks that stop a secret before it is committed | Git, Security |
| Trivy | course | Scanning images for known vulnerabilities | Security, Containers |
| AWS CLI | later | The AWS cloud topic | Cloud (AWS) |
| Terraform | later | Infrastructure as code | Infrastructure as Code |

Why **kind** rather than minikube: kind runs a whole cluster as Docker containers, so it needs nothing
beyond the Docker you already have, starts in under a minute, and is what many CI pipelines use. If
you already use minikube, keep it; the Kubernetes course works with either.

## Time and space

- **Time:** 20 to 45 minutes, mostly downloading. Windows adds a restart and about 10 minutes for WSL.
- **Disk:** about 8 GB free (Docker Desktop and its images are most of it; WSL needs about 3 GB more).
- **Memory:** 8 GB of RAM works; 16 GB makes Docker and a kind cluster comfortable.
- **Network:** the scripts download from the official sources listed in each guide. A school or office
  network that blocks them will make steps fail; see [Troubleshooting](#troubleshooting).

## Check your setup

`./scripts/verify.sh` changes nothing. It checks every tool, prints its version, and checks the
things that are not tools: that Docker is running, that Git knows your name, that you have an SSH
key and that GitHub accepts it.

```text
  CHECK           TIER    STATE VERSION / DETAIL
  --------------- ------- ----- ----------------
  git             core    PASS  2.51.0
  python3         course  PASS  3.12.3
  kind            course  FAIL  missing (Kubernetes (a local cluster))
  terraform       later   --    not installed (Infrastructure as Code, optional for now)
  ...
  docker engine   course  PASS  running
  git identity    setup   PASS  Ada Lovelace <ada@example.com>
  github ssh      setup   PASS  signed in as ada

1 check(s) failed, 0 warning(s). What to do:
  - kind is missing. Re-run the setup script for your system, or install it by hand: docs/linux.md
```

- **PASS**: ready. **WARN**: works, but fix it before the course that needs it (an old version, Docker
  not started, no SSH key yet). **FAIL**: a course will not work until this is fixed. **--**: optional.
- It exits with status 1 if anything failed, so you can use it in your own scripts.
- `--offline` skips the GitHub check, which needs the network.
- On Windows, run it inside Ubuntu: that is where the tools live.

## Companion material

[materials/](materials/README.md) has starter files for each course: a practice repository for Git, a
Dockerfile and compose file, Kubernetes manifests for kind, a CI workflow, runbook templates and more.
They are companions to the in-app courses, not a replacement for them: the courses teach, these let
you try it on your own machine.

## How the scripts install things

- **From the official source**, never a mirror: Homebrew on macOS; on Linux, each vendor's signed apt
  repository (GitHub, NodeSource, Docker, Kubernetes, Aqua Security, Microsoft, HashiCorp) or the
  project's own release page (Go, kind, Helm, actionlint, gitleaks).
- **Release downloads are checked against their published SHA-256.** That catches a corrupted or
  altered download; it does not make a project more trustworthy than it is.
- **Latest stable versions.** The scripts look up the current Node.js LTS line, the current stable Go
  and Kubernetes, and each tool's latest release. Set `NODE_MAJOR=22` (for example) to choose a
  Node.js line yourself.
- **Your profile is edited only where a tool needs it**: on Apple silicon, the one line Homebrew asks
  for in `~/.zprofile`; on Linux, `pipx ensurepath` for pre-commit. Each line is added once.
- **Nothing is uploaded and nothing phones home.** The only network calls are downloads.

## Troubleshooting

Start with `./scripts/verify.sh`: each failure ends with a line saying what to do. The per-system
guides have a troubleshooting section for problems specific to that system.

**A tool is installed but "command not found".** Open a new terminal: a terminal only reads `PATH`
when it starts. verify.sh says "installed at ... but not on PATH" when this is the cause. If a new
terminal does not fix it, log out and back in (Linux), or check that your shell profile has the line
the script added (`~/.zprofile` on a Mac).

**Docker: "permission denied ... docker.sock" (Linux).** You were added to the `docker` group but it
only applies to new logins. Log out and back in, or restart. (Being in that group is equivalent to
having root on the machine; that is normal for a personal development computer, and a reason not to do
it on a shared server.)

**Docker: "Cannot connect to the Docker daemon".** Docker is installed but not running. Open Docker
Desktop (macOS, Windows) and wait for it to say it is running, or `sudo systemctl start docker` (Linux).

**"Could not look up the latest release" or HTTP 403 from GitHub.** GitHub allows 60 anonymous
lookups an hour per network, and a shared school or office network can use them up. Wait an hour, or
run the script from another network.

**Downloads fail on a school or office network.** Some networks block package servers or inspect
traffic. Try a home network or a phone hotspot, or ask the network's administrators to allow the
domains listed in your system's guide.

**apt: "Could not get lock /var/lib/dpkg/lock".** Ubuntu is installing updates in the background. Wait
a few minutes and run the script again.

**Something else.** Run the script again: it continues from where it stopped. If it still fails, open
an issue with your system, the command, and the last 30 lines of output (remove anything personal).

## Contributing

Corrections and improvements are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE), by [NubiCode](https://nubicode.com).

# Windows setup

For Windows 11, or Windows 10 version 2004 (build 19041) or newer. About 30 to 50 minutes, including
one restart. You need an administrator account and about 11 GB free.

## Why WSL2, and not Windows tools

The courses teach the tools that servers, containers and CI runners use, and those run Linux: bash,
`apt`, file permissions, `systemd`, Linux paths. Most of them have no Windows version, and the ones
that do (Git for Windows, Python for Windows) behave differently in ways that make course examples
fail: line endings, path separators, quoting, permissions.

**WSL2** (Windows Subsystem for Linux) runs a real Ubuntu inside Windows, made by Microsoft and built
into Windows. You get the same terminal as a Linux engineer, the courses' commands work unchanged,
and you keep Windows for everything else. VS Code and Docker Desktop are designed to work with it.

So the setup has two halves:

| Where | What | Installed by |
| --- | --- | --- |
| Windows | WSL2 and Ubuntu, Windows Terminal, VS Code, Git for Windows, Docker Desktop | `scripts\windows.ps1` (winget) |
| Ubuntu (inside WSL) | Git, Python, Go, Node.js, kubectl, kind, Helm, the linters and scanners | `scripts/linux.sh` |

Your projects live **inside Ubuntu**, in your Linux home folder (`~`), not in `C:\Users\...`. Files
under `/mnt/c` work, but Git and Docker are many times slower there and line endings get mixed up.

## The quick way

### Part 1: Windows

1. Download the kit: on [the GitHub page](https://github.com/nubicode-org/alfred-setup), **Code >
   Download ZIP**, and unzip it, for example to `Downloads\alfred-setup`.
2. Open **PowerShell as administrator**: Start, type "PowerShell", right-click **Windows PowerShell**,
   **Run as administrator**.
3. Run the script. `-ExecutionPolicy Bypass` lets this one script run without changing your system's
   policy:

   ```powershell
   cd $HOME\Downloads\alfred-setup
   powershell -ExecutionPolicy Bypass -File .\scripts\windows.ps1 -DryRun   # see what it would do
   powershell -ExecutionPolicy Bypass -File .\scripts\windows.ps1
   ```

   Add `-NoDocker` if you will run Docker Engine inside Ubuntu instead (see below).

4. **Restart** if it says so. That finishes turning on WSL.

### Part 2: Ubuntu

5. Open **Ubuntu** from the Start menu. The first time, it asks for a Linux user name and password.
   They are only for Ubuntu and do not have to match your Windows ones. The password is what `sudo`
   asks for; nothing appears as you type it.
6. Open **Docker Desktop**, accept its terms, then **Settings > Resources > WSL integration**, turn on
   **Ubuntu**, and **Apply & restart**. Now `docker` works inside Ubuntu.
7. In the Ubuntu window:

   ```bash
   git clone https://github.com/nubicode-org/alfred-setup.git ~/alfred-setup
   cd ~/alfred-setup
   ./scripts/linux.sh
   ```

8. Close Ubuntu and open it again, do [Git identity and SSH](git-and-ssh.md) **inside Ubuntu**, and
   run `./scripts/verify.sh`.

From now on, open your work from Ubuntu: `cd` into a project and run `code .`. VS Code opens on
Windows, connected to Ubuntu ("WSL: Ubuntu" in its bottom-left corner).

## Step by step, by hand

### 1. WSL2 and Ubuntu

In an administrator PowerShell:

```powershell
wsl --install --distribution Ubuntu
```

Restart when asked. Check, after opening Ubuntu once: `wsl --list --verbose` shows Ubuntu with
`VERSION 2`. If it says 1: `wsl --set-version Ubuntu 2`.

If `wsl --install` says virtualization is not enabled, turn on **Intel VT-x** or **AMD-V / SVM** in
your PC's firmware (BIOS/UEFI) settings; your PC maker's support site says how.

### 2. Windows apps, with winget

`winget` is built into Windows 11 and current Windows 10. If PowerShell does not know it, install
**App Installer** from the Microsoft Store.

```powershell
winget install --id Microsoft.WindowsTerminal --exact
winget install --id Microsoft.VisualStudioCode --exact
winget install --id Git.Git --exact
winget install --id Docker.DockerDesktop --exact
```

- **Windows Terminal** is the best place to use Ubuntu and PowerShell side by side (preinstalled on
  Windows 11).
- **VS Code**, then its **WSL** extension: `code --install-extension ms-vscode-remote.remote-wsl`. The
  other [extensions](vscode.md) install from inside Ubuntu.
- **Git for Windows** is optional for the courses (you use Git inside Ubuntu). It gives you Git
  Credential Manager, useful if you also clone over HTTPS from Windows.
- **Docker Desktop**: see licensing below.

### 3. Everything else, inside Ubuntu

Follow [linux.md](linux.md) from inside Ubuntu, or run `./scripts/linux.sh`. In WSL the script knows
to leave Docker and VS Code to Windows.

## Docker: Desktop or Engine inside WSL

**Docker Desktop** (the default) runs Docker for Windows and Ubuntu together, with a window to see
containers. It is free for personal use, education, open source and small businesses (under 250
employees and under US$10 million revenue); a larger employer needs a paid subscription, so ask before
installing it on a work PC.

**Docker Engine inside WSL** is free for everyone and lighter, with no window. Run the Windows script
with `-NoDocker`, then in Ubuntu:

1. Turn on systemd, so Docker starts by itself. In Ubuntu, `sudo nano /etc/wsl.conf` and add:

   ```ini
   [boot]
   systemd=true
   ```

   Then, in PowerShell, `wsl --shutdown`, and open Ubuntu again. (Ubuntu installed by a current
   `wsl --install` usually has this already.)

2. `./scripts/linux.sh --docker-engine`, then close Ubuntu and open it again.

Do not use both at once: with Engine inside Ubuntu, leave Docker Desktop's WSL integration off.

## Check it works

Inside Ubuntu:

```bash
./scripts/verify.sh
docker run --rm hello-world
kind create cluster --name alfred
kubectl get nodes
kind delete cluster --name alfred
```

## Troubleshooting

**`wsl --install` prints help instead of installing.** WSL is already partly installed. Run
`wsl --update`, then `wsl --install --distribution Ubuntu`.

**"WslRegisterDistribution failed with error: 0x80370102".** Virtualization is off in your PC's
firmware, or **Virtual Machine Platform** is off: Start > "Turn Windows features on or off" > tick
**Virtual Machine Platform** and **Windows Subsystem for Linux**, restart.

**`docker: command not found` inside Ubuntu.** Docker Desktop's WSL integration is off for Ubuntu
(step 6), or Docker Desktop is not running. Turn it on, then close and reopen Ubuntu.

**`$'\r': command not found` or `bad interpreter` running a script.** The file has Windows line
endings, usually because it was cloned or edited on the Windows side. Clone inside Ubuntu (step 7).
To fix one file: `sed -i 's/\r$//' file.sh`.

**Running scripts is disabled on this system** (PowerShell). Use the `powershell -ExecutionPolicy
Bypass -File ...` form above, which applies to that one run only.

**Ubuntu is very slow with Git or Docker.** Your project is under `/mnt/c`. Move it into `~` inside
Ubuntu.

**WSL uses too much memory.** Create `C:\Users\<you>\.wslconfig` with:

```ini
[wsl2]
memory=6GB
```

then `wsl --shutdown` in PowerShell.

**VS Code opens but cannot see Ubuntu's files.** Open it from Ubuntu with `code .`, or in VS Code,
F1 > **WSL: Connect to WSL**. The bottom-left corner should say "WSL: Ubuntu".

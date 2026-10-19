# VS Code and its extensions

The guides assume [VS Code](https://code.visualstudio.com), because it is free, runs on every system,
and edits files inside WSL as if they were local. Any editor works; if you already have one you like,
keep it and install the equivalent plugins.

The setup scripts install the extensions below. To install them yourself, run each line, or open this
repository in VS Code and accept "Install recommended extensions" (the list is in
[`.vscode/extensions.json`](../.vscode/extensions.json)).

```bash
code --install-extension editorconfig.editorconfig
code --install-extension redhat.vscode-yaml
code --install-extension ms-python.python
code --install-extension golang.go
code --install-extension timonwong.shellcheck
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension github.vscode-github-actions
```

| Extension | What it does | Courses |
| --- | --- | --- |
| EditorConfig | Applies a project's indentation and line-ending rules | All |
| YAML (Red Hat) | Validates YAML as you type, with schemas for Kubernetes, Compose and workflows | CI/CD, Containers, Kubernetes |
| Python | Running, linting and debugging Python | Programming |
| Go | Formatting, completion and tests for Go | Programming |
| ShellCheck | Underlines shell-script mistakes while you write them | OS Concepts, Local Env |
| Docker / Container Tools | Dockerfile and compose help, and a view of images and containers | Containers |
| Kubernetes | Manifest help and a view of your kind cluster | Kubernetes |
| GitHub Actions | Workflow syntax, and your runs without leaving the editor | CI/CD |

**Windows:** install **WSL** (`ms-vscode-remote.remote-wsl`) on the Windows side (windows.ps1 does).
Then, inside Ubuntu, `code .` opens the folder in VS Code connected to WSL, and the extensions above
install into that connection, which is where they need to be.

## The `code` command

The scripts use `code` to install extensions. If it is missing:

- **macOS:** open VS Code, press Cmd+Shift+P, run **Shell Command: Install 'code' command in PATH**,
  and open a new terminal.
- **Windows:** the installer adds it; open a new PowerShell or Ubuntu window.
- **Linux:** the apt package adds it.

## Settings worth changing

In **Settings** (Cmd+, or Ctrl+,):

- **Files: Insert Final Newline** and **Files: Trim Trailing Whitespace**: on. Linters and diffs will
  thank you.
- **Files: Eol**: `\n`. Shell scripts with Windows line endings fail with `bad interpreter` or
  `$'\r': command not found`.
- **Editor: Render Whitespace**: `boundary`, so a tab in YAML is visible before it breaks a file.

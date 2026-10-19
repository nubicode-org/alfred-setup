# Git identity and an SSH key for GitHub

The same on every system. On Windows, do this **inside Ubuntu**, where your repositories will live.
About 10 minutes. You need a free [GitHub](https://github.com/signup) account.

The setup scripts do not do this for you on purpose: the key is yours, and the Local Environment and
Git courses explain what each step is doing.

## 1. Tell Git who you are

Every commit records a name and an email. Use the email of your GitHub account, or the private
`...@users.noreply.github.com` address from GitHub's [email settings](https://github.com/settings/emails)
if you would rather not publish your real one.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
```

`init.defaultBranch main` matches what GitHub uses. `pull.rebase false` makes `git pull` merge, which
is the behavior the Git course starts from; the course explains when to choose rebase instead.

Pick an editor for commit messages, so Git never drops you into one you cannot exit:

```bash
git config --global core.editor "code --wait"    # VS Code
# or: git config --global core.editor "nano"
```

## 2. Create an SSH key

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

- Press Enter to accept the default file (`~/.ssh/id_ed25519`).
- **Choose a passphrase.** It protects the key if your laptop is lost or copied. You can make your
  computer remember it (below) so you are not typing it all day.
- The file **without** `.pub` is your private key. Never paste it anywhere, never commit it, never send
  it to anyone, including support. The `.pub` file is the one you share.

Remember the passphrase:

- **macOS:** add this to `~/.ssh/config` (create the file if it does not exist), then run
  `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` once:

  ```text
  Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
  ```

- **Linux and WSL:** desktop Linux usually offers to remember it the first time you use it. In WSL or
  on a server, run `eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519` in a terminal session to
  type it once for that session. (`keychain`, from apt, can make that permanent.)

## 3. Add the key to GitHub

Print the public key and copy all of it, from `ssh-ed25519` to your email:

```bash
cat ~/.ssh/id_ed25519.pub
```

On GitHub: **Settings > SSH and GPG keys > New SSH key**. Give it a name that says which computer it
is ("Ada's laptop"), keep the type **Authentication Key**, paste, save.

Or with the GitHub CLI, which also signs you in to `gh` for the Git and CI/CD courses:

```bash
gh auth login        # choose GitHub.com, SSH, and your existing key; it uploads the .pub for you
```

## 4. Test it

```bash
ssh -T git@github.com
```

The first time, SSH shows GitHub's key fingerprint and asks whether to trust it. Check it against
[GitHub's published fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
(the ED25519 one is `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`), then type `yes`.

You should see: `Hi <your-username>! You've successfully authenticated, but GitHub does not provide
shell access.` That message is success. Then `./scripts/verify.sh` shows `github ssh  PASS`.

From now on, clone with the SSH address (`git@github.com:owner/repo.git`), not the `https://` one.

## Troubleshooting

**`Permission denied (publickey)`.** GitHub did not receive a key it knows. Check, in order:

1. `ls ~/.ssh` shows `id_ed25519` and `id_ed25519.pub`.
2. The key on GitHub's settings page is the same as `cat ~/.ssh/id_ed25519.pub`.
3. `ssh -vT git@github.com 2>&1 | grep -i offering` lists your key. If it lists none, add it to the
   agent (step 2) or add an `IdentityFile` line to `~/.ssh/config`.
4. On Windows: you created the key inside Ubuntu, not in PowerShell (they are separate home folders).

**`Host key verification failed`.** Your `~/.ssh/known_hosts` has an old entry for GitHub. Remove it
with `ssh-keygen -R github.com` and test again, checking the fingerprint as above.

**Port 22 is blocked** (some school and office networks): GitHub also accepts SSH on port 443. Add to
`~/.ssh/config`:

```text
Host github.com
  Hostname ssh.github.com
  Port 443
  User git
```

**Commits show the wrong name or email.** `git config --global --list` shows what Git uses. A
repository can override it with its own `git config user.email`, which `git config --list
--show-origin` reveals.

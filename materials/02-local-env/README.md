# Local Environment Setup: companion material

Goes with the **Local Environment Setup** course on Alfred Learning. The course teaches these ideas in
the in-page terminal; these are the same files for your real machine.

| File | Course module | Where it goes |
| --- | --- | --- |
| [dotfiles/profile.sh](dotfiles/profile.sh) | Shell profiles | Source it from `~/.zshrc` or `~/.bashrc` |
| [dotfiles/gitignore_global](dotfiles/gitignore_global) | Git configuration | `~/.config/git/ignore` |
| [ssh-config.example](ssh-config.example) | SSH keys and config | Merge into `~/.ssh/config` |
| [rebuild-runbook.md](rebuild-runbook.md) | The capstone | Keep it with your notes, update it when your setup changes |

Try them without risk:

```bash
# A profile that is safe on a machine where nothing is installed yet.
bash -n dotfiles/profile.sh && echo "syntax ok"
env -i HOME="$HOME" PATH=/usr/bin:/bin bash --noprofile --norc -c '. ./dotfiles/profile.sh && echo "loaded with nothing installed"'

# Use the global gitignore.
mkdir -p ~/.config/git && cp dotfiles/gitignore_global ~/.config/git/ignore
git check-ignore -v .DS_Store    # shows which rule matched
```

Never copy someone else's dotfiles wholesale, these included. Read each line, keep the ones you
understand and want, as the course recommends.

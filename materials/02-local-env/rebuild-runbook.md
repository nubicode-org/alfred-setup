# Rebuilding my machine

The course's capstone: if this laptop died today, could I be working again on a new one by tonight?
Write it so someone who is not you could follow it. Test it once, on a spare account or a VM.

## What I need before I start

- [ ] My password manager's master password and recovery method (not stored on this laptop)
- [ ] Two-factor authentication on a device other than this laptop
- [ ] My dotfiles repository URL: ___

## 1. Base tools

Run the setup kit: `./scripts/<system>.sh`, then `./scripts/verify.sh`.

Anything I install that the kit does not:

| Tool | Why | How |
| --- | --- | --- |
| | | |

## 2. Identity

- [ ] Git name and email (docs/git-and-ssh.md, step 1)
- [ ] A **new** SSH key for this machine, added to GitHub; the old machine's key removed from GitHub
- [ ] `gh auth login`

## 3. My configuration

```bash
git clone git@github.com:<me>/dotfiles.git ~/dotfiles
# then: link or source each file
```

## 4. My projects

| Repository | Clone into | Anything to run after cloning |
| --- | --- | --- |
| | | |

## 5. What I would have lost

Things that live only on this laptop and are not backed up (fix each one, then delete the row):

| What | Where | Fix |
| --- | --- | --- |
| | | |

Last tested: ___

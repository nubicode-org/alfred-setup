# Contributing

Thank you for helping learners get set up. Fixes for a step that no longer works are the most useful
contribution of all: tools move their download pages and change their install commands often.

## Reporting a problem

Open an issue with your operating system and version, the command you ran, and the last 30 lines of
its output. Remove anything personal (user names in paths are fine; tokens and keys are not).

## Changing the kit

- **Keep the scripts safe to re-run.** Every install checks first and skips what is present.
- **Every change goes through `run` (or `Invoke-Change` on Windows)**, so `--dry-run` shows it.
- **No secrets, ever.** The scripts must not ask for or store a token, key or account.
- **Official sources only**, with the signing key or published checksum checked.
- **The guide and the script say the same thing.** A step added to a script is added to that system's
  guide in `docs/`, with the command a learner would type by hand.
- **A new tool is used by a course.** Add it to the script, the guide, `scripts/verify.sh` and the
  table in the README, with the course that uses it.
- **Companion material stays a companion.** Files in `materials/` support an Alfred Learning course;
  they do not replace it.

Before opening a pull request, run what CI runs:

```bash
shellcheck scripts/*.sh scripts/lib/*.sh materials/*/*.sh materials/*/*/*.sh
./scripts/linux.sh --dry-run        # or macos.sh, on a Mac
./scripts/verify.sh --offline
yamllint -c materials/10-cicd/.yamllint.yaml .
actionlint .github/workflows/*.yml materials/10-cicd/.github/workflows/*.yml
```

The CI workflow also runs `scripts/linux.sh` for real in fresh Ubuntu and Debian containers, twice, to
prove the second run changes nothing. Windows is checked with PSScriptAnalyzer; please test a change
to `windows.ps1` on a real Windows machine and say so in the pull request.

Copy is US English, plain and direct: say what a step does and why, in the fewest words that are
still clear to someone doing this for the first time.

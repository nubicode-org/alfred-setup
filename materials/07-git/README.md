# Version Control with Git: companion material

Goes with the **Version Control with Git** course on Alfred Learning. Every exercise in that course
runs in the in-page terminal, so you need nothing from here to finish it. These let you repeat the
exercises with real Git, including the parts the in-page terminal cannot do: interactive rebase,
pushing to GitHub, and hooks.

## A practice repository

```bash
./make-practice-repo.sh ~/git-practice
cd ~/git-practice
git log --oneline --graph --all
```

It builds a small repository with history, two branches that have diverged, and a merge that will
conflict, so you can practice without risking a real project. It refuses to touch a folder that
already exists. Delete the folder and run it again for a fresh start.

What to try, following the course's modules:

1. **Inspect**: `git log --oneline --graph --all`, `git show HEAD~1`, `git diff main feature/greeting`.
2. **Merge and resolve**: `git merge feature/greeting`, fix `greeting.txt`, `git add`, `git commit`.
3. **Undo**: `git reset --hard HEAD~1`, then get it back with `git reflog` and `git reset --hard HEAD@{1}`.
4. **Rebase instead**: `git switch feature/greeting && git rebase main`, then `git rebase --abort` or finish it.
5. **Squash** (the real interactive rebase the in-page terminal skips): `git rebase -i HEAD~3`.
6. **Push**: create an empty repository on GitHub, `git remote add origin git@github.com:<you>/git-practice.git`,
   `git push -u origin main`.

## Hooks with pre-commit

[pre-commit-config.yaml](pre-commit-config.yaml) runs gitleaks (secrets) and a few file checks before
each commit. In any repository of yours:

```bash
cp /path/to/alfred-setup/materials/07-git/pre-commit-config.yaml .pre-commit-config.yaml
pre-commit install          # installs the hook into .git/hooks
pre-commit run --all-files  # run it on everything once
```

The hook runs on your machine, so it can be skipped (`git commit --no-verify`). That is why the
course also runs the same checks in CI, where they cannot be.

#!/usr/bin/env bash
# Build a practice Git repository with history, two diverged branches and a merge that conflicts.
#   ./make-practice-repo.sh <new-directory>
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 <new-directory>" >&2; exit 2; }
target=$1
[ ! -e "$target" ] || { echo "$target already exists. Choose a new folder, or delete it first." >&2; exit 1; }

mkdir -p "$target"
cd "$target"
git init -q -b main

# A fixed identity inside this repository only, so commits work before you set up your own.
git config user.name "Practice Bot"
git config user.email "practice@example.com"

commit() { git add -A && git commit -q -m "$1"; }

printf '# Practice project\n\nA small repository for trying Git safely.\n' >README.md
commit "Add README"

printf 'Hello\n' >greeting.txt
commit "Add greeting"

printf 'node_modules/\n.env\n' >.gitignore
commit "Ignore dependencies and local env files"

git switch -q -c feature/greeting
printf 'Hello, world\n' >greeting.txt
commit "Greet the world"
printf 'Run: cat greeting.txt\n' >>README.md
commit "Document how to run it"

git switch -q main
printf 'Hello, team\n' >greeting.txt
commit "Greet the team"
printf 'MIT\n' >LICENSE
commit "Add license"

echo "Practice repository ready in $(pwd)"
echo "main and feature/greeting both changed greeting.txt, so 'git merge feature/greeting' will conflict."
git log --oneline --graph --all

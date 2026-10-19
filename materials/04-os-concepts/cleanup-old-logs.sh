#!/usr/bin/env bash
# Delete *.log files older than N days under a directory.
# Prints what it would delete unless --delete is given, and refuses paths where a mistake is costly.
#
#   ./cleanup-old-logs.sh <directory> <days> [--delete]
set -euo pipefail

usage() { echo "Usage: $0 <directory> <days> [--delete]" >&2; exit 2; }

[ $# -ge 2 ] || usage
dir=$1
days=$2
mode=${3:-}

case "$days" in
  '' | *[!0-9]*) echo "days must be a whole number, got '$days'" >&2; exit 2 ;;
esac
[ -d "$dir" ] || { echo "not a directory: $dir" >&2; exit 2; }

# Resolve the real path, so "/var/log/../.." cannot sneak past the check below.
real=$(cd "$dir" && pwd -P)
case "$real" in
  / | /bin | /boot | /dev | /etc | /home | /lib* | /opt | /proc | /root | /sbin | /srv | /sys | /usr | /var | "$HOME")
    echo "refusing to clean $real: too broad" >&2
    exit 1
    ;;
esac

# -xdev stays on one filesystem; -print0 and read -d '' survive file names with spaces or newlines.
count=0
while IFS= read -r -d '' file; do
  count=$((count + 1))
  if [ "$mode" = --delete ]; then
    rm -f -- "$file"
    echo "deleted  $file"
  else
    echo "would delete  $file"
  fi
done < <(find "$real" -xdev -type f -name '*.log' -mtime +"$days" -print0)

if [ "$mode" = --delete ]; then
  echo "$count file(s) deleted."
else
  echo "$count file(s) would be deleted. Re-run with --delete to delete them."
fi

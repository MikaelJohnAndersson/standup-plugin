#!/usr/bin/env bash
# scan.sh <data folder> [root ...]: lists the git repos under the roots (two levels deep),
# grouped by their origin's GitHub owner, with the author emails each repo uses. For setup.
data=$1; shift
. "$(dirname "$0")/lib.sh"
[ $# -gt 0 ] || set -- "$HOME/Documents"

for root in "$@"; do
  root=$(expand "$root")
  find "$root" -mindepth 1 -maxdepth 3 -name .git -type d -prune 2>/dev/null | sed 's#/\.git$##'
done | sort -u | while IFS= read -r repo; do
  printf '%s\t%s\t%s\n' "$(owner "$repo" || true)" "$repo" "$(git -C "$repo" config user.email)"
done | sort | awk -F'\t' '
  { o = ($1 == "" ? "(no remote)" : $1) }
  o != last { printf "\n%s\n", o; last = o }
  { printf "  %s  <%s>\n", $2, $3 }'

echo
echo "Global git email: $(git config --global user.email)"

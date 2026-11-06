#!/usr/bin/env bash
# clear.sh <data folder> [all] [--yes]: without --yes, lists what would be deleted; with
# it, deletes the session logs and notes, and with all the config as well.
data=$1; shift
all= yes=
for arg; do case $arg in all) all=1 ;; --yes) yes=1 ;; esac; done

logs=("$data"/log/*.jsonl); [ -e "${logs[0]}" ] || logs=()
entries=0; [ ${#logs[@]} -gt 0 ] && entries=$(cat "${logs[@]}" | grep -c '')
notes=$(grep -c '' "$data/notes.md" 2>/dev/null || echo 0)
size=$(du -sh "$data" 2>/dev/null | cut -f1 | tr -d ' ')

if [ -z "$yes" ]; then
  echo "Folder: $data (${size:-0B})"
  if [ ${#logs[@]} -gt 0 ]; then
    first=$(basename "${logs[0]}" .jsonl) last=$(basename "${logs[${#logs[@]}-1]}" .jsonl)
    echo "Session logs: ${#logs[@]} day(s), $entries entries, $first to $last"
  else
    echo "Session logs: none"
  fi
  echo "Notes: $notes"
  if [ -n "$all" ]; then
    echo "Config: $( [ -e "$data/config.json" ] && echo "will be deleted" || echo none)"
  else
    echo "Config: kept (add \"all\" to delete it too)"
  fi
  exit 0
fi

rm -rf "$data/log" "$data/cursors" "$data/notes.md"
[ -n "$all" ] && rm -f "$data/config.json"
echo "Deleted ${#logs[@]} day(s) of session logs ($entries entries) and $notes note(s)$( [ -n "$all" ] && echo ", and the config")."

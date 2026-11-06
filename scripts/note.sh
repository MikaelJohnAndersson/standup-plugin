#!/usr/bin/env bash
# note.sh <data folder> [text | clear]: adds a note to raise at the next standup, clears
# them, or with no text lists them.
data=$1; shift
notes="$data/notes.md"

case $* in
  "")
    if [ -s "$notes" ]; then cat "$notes"; else echo "No notes."; fi ;;
  clear)
    n=$(grep -c '' "$notes" 2>/dev/null || echo 0)
    rm -f "$notes" && echo "Cleared $n note(s)." ;;
  *)
    mkdir -p "$data" && printf -- '- %s: %s\n' "$(date +%F)" "$*" >>"$notes" && echo "Noted." ;;
esac

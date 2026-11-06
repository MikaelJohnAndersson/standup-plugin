#!/usr/bin/env bash
# capture.sh <data folder>: the Stop and SessionEnd hook. Reads the hook input on stdin and
# appends one line per turn to log/<date>.jsonl: the session title, repo, branch, your
# prompts (shortened) and the files edited. No model calls. Only repos in the config count.
data=$1
. "$(dirname "$0")/lib.sh"
[ -r "$config" ] || exit 0

input=$(cat)
session=$(jq -r '.session_id // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$session" ] && [ -r "$transcript" ] || exit 0

# Only the lines added since the last capture of this session
mkdir -p "$data/log" "$data/cursors"
cursor_file="$data/cursors/$session"
done_lines=$(cat "$cursor_file" 2>/dev/null || echo 0)
total=$(wc -l <"$transcript" | tr -d ' ')
[ "$total" -gt "$done_lines" ] || exit 0
echo "$total" >"$cursor_file"

in_scope "${cwd:-.}" || exit 0

title=$(grep '"ai-title"' "$transcript" | tail -1 | jq -r '.aiTitle // empty' 2>/dev/null)
entry=$(sed -n "$((done_lines + 1)),${total}p" "$transcript" | jq -Rnc \
  --arg session "$session" --arg title "$title" --arg cwd "$cwd" --arg ts "$(date -u +%FT%TZ)" '
  [inputs | fromjson?] as $lines
  | {
      ts: $ts, session: $session, title: $title,
      cwd: ([$lines[].cwd | select(.)] | last // $cwd),
      branch: ([$lines[].gitBranch | select(.)] | last),
      prompts: [
        $lines[] | select(.type == "user" and (.isMeta | not)) | .message.content
        | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join(" ")) end
        | gsub("\\s+"; " ") | select(length > 0 and (startswith("<") | not)) | .[0:200]
      ],
      files: [
        $lines[] | select(.type == "assistant") | .message.content[]?
        | select(.type == "tool_use" and (.name | IN("Edit", "Write", "MultiEdit", "NotebookEdit")))
        | .input.file_path // .input.notebook_path | select(.)
      ] | unique
    }
  | select((.prompts | length) > 0 or (.files | length) > 0)')
[ -n "$entry" ] && echo "$entry" >>"$data/log/$(date +%F).jsonl"

# Keep logs for retentionDays (14 by default)
keep=$(conf .retentionDays); keep=${keep:-14}
find "$data/log" "$data/cursors" -type f -mtime +"$keep" -delete 2>/dev/null
exit 0

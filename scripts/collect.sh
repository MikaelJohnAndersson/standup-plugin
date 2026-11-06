#!/usr/bin/env bash
# collect.sh <data folder> [YYYY-MM-DD]: prints what you did from that day (by default the
# last workday) until today: commits, pull requests, captured sessions and saved notes.
data=$1 since=$2
. "$(dirname "$0")/lib.sh"
[ -r "$config" ] || { echo "Not set up yet: run /standup:setup first."; exit 1; }

today=$(date +%F)
since=${since:-$(last_workday)}
[[ $since =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "Give the start date as YYYY-MM-DD."; exit 1; }
# Up to the start of today, unless the period starts today
if [ "$since" = "$today" ]; then until=now; else until="$today 00:00"; fi
echo "Period: $since 00:00 until $until"

echo; echo "## Commits"
authors=(); while IFS= read -r a; do authors+=(--author="$a"); done < <(conf .authors)
found=
while IFS= read -r repo; do
  log=$(git -C "$repo" log --all --no-merges --source "${authors[@]}" \
    --since="$since 00:00" --until="$until" --date=format:'%a %H:%M' \
    --format='- %cd %S %h %s' 2>/dev/null | sed 's# refs/heads/# #; s# refs/remotes/origin/# #')
  [ -n "$log" ] && found=1 && printf '\n### %s (%s)\n%s\n' "$(basename "$repo")" "$repo" "$log"
done < <(repos)
[ -n "$found" ] || echo "None."

echo; echo "## Pull requests"
owners=(); while IFS= read -r o; do owners+=(--owner "$o"); done < <(conf .orgs)
if ! command -v gh >/dev/null; then
  echo "Skipped: gh is not installed."
elif [ ${#owners[@]} -eq 0 ]; then
  echo "Skipped: no orgs in the config."
else
  # PRs updated in the period: yours, then others' you reviewed or commented on at some point
  prs=()
  for role in author reviewed-by commenter; do
    out=$(gh search prs "${owners[@]}" --"$role" @me --updated ">=$since" --limit 50 \
      --json number,title,state,isDraft,url,repository,author 2>&1) \
      || { echo "Skipped: gh search failed: $out"; prs=(); break; }
    prs+=("$out")
  done
  [ ${#prs[@]} -gt 0 ] && jq -rs '
    def line: "- \(.repository.name)#\(.number) \(.title) [\(if .isDraft then "draft" else .state end)] \(.url)";
    (.[0] | map(.url)) as $mine | (.[0] | map(line)) as $own
    | ([.[1][], .[2][]] | unique_by(.url) | map(select(.url | IN($mine[]) | not)) | map(line)) as $others
    | "### Yours", (if $own == [] then "None." else $own[] end),
      "", "### Reviewed or commented on (updated in the period; your activity may be older)",
      (if $others == [] then "None." else $others[] end)' <<<"$(printf '%s\n' "${prs[@]}")"
fi

echo; echo "## Claude Code sessions"
logs=()
for f in "$data"/log/*.jsonl; do
  [ -e "$f" ] || continue
  d=$(basename "$f" .jsonl)
  [[ ! $d < $since ]] && { [[ $d < $today ]] || [ "$since" = "$today" ]; } && logs+=("$f")
done
if [ ${#logs[@]} -eq 0 ]; then
  echo "None captured."
else
  jq -rs 'group_by(.session) | sort_by(.[0].ts)[] |
    (.[0].cwd // "") as $cwd |
    "\n### \(map(.title | select(. != "")) | last // "Untitled session")",
    "repo: \($cwd | split("/") | last), branch: \(map(.branch | select(.)) | last // "none"), \(.[0].ts[0:16]) to \(.[-1].ts[11:16]) UTC",
    "prompts:", ([.[].prompts[]] | .[0:15][] | "- \(.)"),
    (([.[].files[]] | unique | map(ltrimstr($cwd + "/"))) as $files
      | if ($files | length) > 0 then "files: \($files[0:20] | join(", "))" else empty end)' "${logs[@]}"
fi

echo; echo "## Notes to raise"
if [ -s "$data/notes.md" ]; then cat "$data/notes.md"; else echo "None."; fi

echo; echo "## Config"
echo "Linear workspace: $(conf .linearWorkspace || true)"

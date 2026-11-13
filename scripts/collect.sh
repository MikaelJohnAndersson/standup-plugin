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
orgs=(); while IFS= read -r o; do orgs+=("$o"); done < <(conf .orgs)
if ! command -v gh >/dev/null; then
  echo "Skipped: gh is not installed."
elif [ ${#orgs[@]} -eq 0 ]; then
  echo "Skipped: no orgs in the config."
elif ! me=$(gh api user --jq .login 2>&1); then
  echo "Skipped: gh failed: $(echo "$me" | head -1)"
else
  # In parallel: PRs updated in the period (yours, reviewed, commented on) for titles and
  # state, and each org's events for what you did when. Events carry no PR titles. Each
  # source fails on its own and says so in an "Incomplete:" line, keeping the others.
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  owners=(); for o in "${orgs[@]}"; do owners+=(--owner "$o"); done
  for role in author reviewed-by commenter; do
    { gh search prs "${owners[@]}" --"$role" @me --updated ">=$since" --limit 50 \
        --json number,title,state,isDraft,url,repository >"$tmp/$role" 2>"$tmp/$role.err" || {
        echo "Incomplete: PRs by role $role left out, gh failed: $(head -1 "$tmp/$role.err")" >"$tmp/$role.warn"
        echo '[]' >"$tmp/$role"; }; } &
  done
  # An org's feed holds everyone's events in it, newest first, and GitHub serves 3 pages
  # at most, so stop at the first page that reaches back before the period
  for o in "${orgs[@]}"; do
    { f=$tmp/events.$o
      for page in 1 2 3; do
        if ! gh api "users/$me/events/orgs/$o?per_page=100&page=$page" --jq '.[]' >"$f.$page" 2>"$f.err"; then
          echo "Incomplete: $o's events left out, gh failed: $(head -1 "$f.err")" >"$f.warn"
          rm -f "$f".[0-9]; break
        fi
        # A short page is the end of the feed
        [ "$(grep -c '' "$f.$page")" -lt 100 ] && break
        [ "$(tail -1 "$f.$page" | jq -r '.created_at[0:10]')" \< "$since" ] && break
        [ "$page" = 3 ] && echo "Incomplete: $o's events reach back only to $(tail -1 "$f.$page" |
          jq -r '.created_at | fromdateiso8601 | localtime | strftime("%a %H:%M")'), earlier activity is left out" >"$f.warn"
      done; } &
  done
  wait
  cat "$tmp"/*.warn 2>/dev/null
  end=$([ "$until" = now ] && echo 9999 || echo "$until")
  jq -rn --slurpfile mine "$tmp/author" --slurpfile rev "$tmp/reviewed-by" \
    --slurpfile com "$tmp/commenter" --slurpfile ev <(cat "$tmp"/events.*.[0-9] 2>/dev/null | jq -s .) \
    --arg from "$since 00:00" --arg to "$end" --arg me "$me" '
    def line: "- \(.repository.name)#\(.number) \(.title) [\(if .isDraft then "draft" else .state end)] \(.url)";
    def at: .created_at | fromdateiso8601 | localtime | strftime("%a %H:%M");
    ($mine[0] | map(.url)) as $own
    | ([$mine[0][], $rev[0][], $com[0][]] | map({key: "\(.repository.name)#\(.number)", value: .}) | from_entries) as $pr
    | [$ev[0][] | select(.actor.login == $me
        and (.created_at | fromdateiso8601 | localtime | strftime("%Y-%m-%d %H:%M")) as $t
        | $t >= $from and $t < $to)] as $evs
    | ($evs | map(select(.payload.pull_request.number // .payload.issue.number))
        | group_by("\(.repo.name)#\(.payload.pull_request.number // .payload.issue.number)")
        | map(sort_by(.created_at) | (.[0] | "\(.repo.name | split("/")[1])#\(.payload.pull_request.number // .payload.issue.number)") as $k
          | "- \($k) \($pr[$k].title // "(title not found)") \($pr[$k].url // "https://github.com/\(.[0].repo.name)/pull/\(.[0].payload.pull_request.number // .[0].payload.issue.number)"): " + ([
              (.[] | select(.type == "PullRequestReviewEvent") | "\(at) review \(.payload.review.state | ascii_downcase | gsub("_"; " "))"),
              (.[] | select(.type == "PullRequestEvent") | "\(at) \(if .payload.pull_request.merged then "merged" else .payload.action end) the PR"),
              (map(select(.type == "PullRequestReviewCommentEvent")) | length | select(. > 0) | "\(.) inline comment(s)"),
              (.[] | select(.type == "IssueCommentEvent") | "\(at) comment")
            ] | join(", ")))) as $acts
    | ($evs | map(select(.type == "PushEvent"))
        | group_by(.repo.name, .payload.ref)
        | map("- pushed \(length)x to \(.[0].repo.name | split("/")[1]) \(.[0].payload.ref | ltrimstr("refs/heads/")), \(.[0] | at) to \(.[-1] | at)")) as $pushes
    | "### Yours (updated in the period)",
      ($mine[0] | if . == [] then "None." else .[] | line end),
      "", "### What you did on GitHub in the period (your own reviews, comments, pushes; times local)",
      (if $acts + $pushes == [] then "None." else ($acts + $pushes)[] end),
      "", "### Others you reviewed or commented on earlier, updated in the period by someone else",
      ([$rev[0][], $com[0][]] | unique_by(.url)
        | map(select((.url | IN($own[]) | not) and ("\(.repository.name)#\(.number)" as $k | $acts | map(startswith("- \($k) ")) | any | not)))
        | if . == [] then "None." else .[] | line end)'
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

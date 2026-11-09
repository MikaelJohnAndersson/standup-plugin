---
description: Summarize what the user did since their last workday (commits, PRs, Linear, Claude Code sessions, saved notes), ready to say at standup
argument-hint: "[YYYY-MM-DD to start from instead of the last workday]"
---

1. Collect the raw material with the Bash tool, passing the user's arguments through as they are:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/collect.sh" "${CLAUDE_PLUGIN_DATA}" $ARGUMENTS
   ```

   If it says the plugin isn't set up, tell the user to run `/standup:setup` and stop.

2. If Linear tools are connected, look up in one parallel batch the issues assigned to the user and updated in the period, and the ticket IDs that appear in branch names, commits, PR titles and prompts (for example `TC-1036`), for their titles and status. Skip this step without comment if there are no Linear tools.

3. Write the summary from that material only; never fill gaps with guesses. Use exactly these three headings, in this order, and nothing else; keep it short enough to say aloud in a minute:

   - **What I did**: one line per ticket or topic, merging the commits, PRs, reviews and sessions that belong together. Include reviews from "What you did on GitHub" (approved, commented, changes requested) and anything that moved your own PRs forward, such as replying to review. Leave out "Others you reviewed or commented on earlier": that activity is older than the period.
   - **What I'll do today**: the likely next steps, from open PRs, in-progress tickets, unfinished sessions and saved notes. These are suggestions.
   - **Blockers**: what waits on someone else, such as reviews, approvals or decisions. Write "None" if there are none.

   Fold saved notes into whichever section they belong to. Write ticket IDs as links when the config names a Linear workspace: `[TC-1036](https://linear.app/<workspace>/issue/TC-1036)`. Link PRs by their URL. Write in the language the user writes in.

4. If there were saved notes, ask with AskUserQuestion whether to clear them now (they've been raised) or keep them. On clear, run `"${CLAUDE_PLUGIN_ROOT}/scripts/note.sh" "${CLAUDE_PLUGIN_DATA}" clear` and say what it printed in one line.

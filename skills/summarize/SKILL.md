---
description: Summarize what the user did since their last workday (commits, PRs, Linear, Claude Code sessions, saved notes), ready to say at standup
argument-hint: "[YYYY-MM-DD to start from instead of the last workday]"
---

1. Collect the raw material with the Bash tool, passing the user's arguments through as they are:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/collect.sh" "${CLAUDE_PLUGIN_DATA}" $ARGUMENTS
   ```

   If it says the plugin isn't set up, tell the user to run `/standup:setup` and stop.

2. If Linear tools are connected, look up the issues assigned to the user and updated in the period it printed, and the ticket IDs that appear in branch names, commits, PR titles and prompts (for example `TC-1036`), for their titles and status. Skip this step without comment if there are no Linear tools.

3. Write the summary from that material only; never fill gaps with guesses. Group by ticket or topic, merging the commits, PRs and sessions that belong together. Keep it short enough to say aloud in a minute or two:

   - **Done**: what moved forward, one line per ticket or topic, with PR state where there is one
   - **Today**: the likely next steps, from open PRs, in-progress tickets and unfinished sessions; say these are suggestions
   - **To raise**: blockers, reviews waited on, decisions needed from others, and every saved note

   Write ticket IDs as links when the config names a Linear workspace: `[TC-1036](https://linear.app/<workspace>/issue/TC-1036)`. Link PRs by their URL. Write in the language the user writes in.

4. If there were saved notes, end with one line: run `/standup:note clear` once they're raised.

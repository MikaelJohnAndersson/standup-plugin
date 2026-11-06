---
description: Set up the standup plugin, choosing which repos, GitHub orgs and author emails to include
argument-hint: "[folder to scan, ~/Documents by default]"
disable-model-invocation: true
---

1. Show the current config, if any, with the Bash tool:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" "${CLAUDE_PLUGIN_DATA}"
   ```

2. Scan for repos, passing the user's arguments through as they are:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/scan.sh" "${CLAUDE_PLUGIN_DATA}" $ARGUMENTS
   ```

   It lists the repos grouped by the GitHub owner of their `origin`, with the email each one commits with.

3. Ask the user, with the AskUserQuestion tool where it's available:
   - which owners to include (multi-select). Every repo of a chosen owner is included, new ones too. Suggest the work-looking ones, and keep personal accounts out unless the user picks them.
   - whether to add single repos (such as ones under "(no remote)") or leave out single repos of a chosen owner. These become `include` and `exclude` paths.
   - which author emails are theirs, from the emails the scan shows.
   - optionally, their Linear workspace slug (the part after `linear.app/`), for ticket links.

4. Save the config, as one JSON object in single quotes:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" "${CLAUDE_PLUGIN_DATA}" write '<json>'
   ```

   The keys are `roots` (folders to look for repos in, `~` allowed; the scanned folders), `orgs`, `include`, `exclude`, `authors`, `linearWorkspace` and `retentionDays` (14 unless the user asks otherwise).

5. Show the repos it now includes, and say that sessions in those repos are captured from now on and that `/standup:summarize` summarizes them.

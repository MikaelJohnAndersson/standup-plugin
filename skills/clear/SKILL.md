---
description: Delete everything the standup plugin has stored (session logs and notes, and with "all" the config), after confirming
argument-hint: "[all]"
disable-model-invocation: true
---

1. List what would be deleted with the Bash tool, passing the user's arguments through as they are:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/clear.sh" "${CLAUDE_PLUGIN_DATA}" $ARGUMENTS
   ```

2. Show the user what it printed and ask them to confirm, with the AskUserQuestion tool where it's available: "Delete" or "Keep everything". If there's nothing to delete, say so and stop.

3. Only if the user confirms, delete it:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/clear.sh" "${CLAUDE_PLUGIN_DATA}" $ARGUMENTS --yes
   ```

   Tell the user what it printed, in one line. If the user didn't confirm, say nothing was deleted.

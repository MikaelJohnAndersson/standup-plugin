---
description: Save a note to raise at the next standup, list the notes, or clear them
argument-hint: "[text | clear]"
disable-model-invocation: true
---

Run this command with the Bash tool, passing the user's arguments through as they are, in single quotes (escape any single quote in them as `'\''`):

```
"${CLAUDE_PLUGIN_ROOT}/scripts/note.sh" "${CLAUDE_PLUGIN_DATA}" '$ARGUMENTS'
```

Tell the user what it printed, in one line, or show the notes as printed.

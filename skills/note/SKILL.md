---
description: Save a note to raise at the next standup, list the notes, or clear them
argument-hint: "[text | clear]"
disable-model-invocation: true
---

The user's arguments: `$ARGUMENTS`

Decide what to save from them:

- No arguments, or `clear`: pass them through unchanged.
- Text that stands on its own: save it word for word.
- Text that points at this session ("the above", "what we just did", "this"): write one short note from the session that makes sense on its own the next day. Name the PRs, tickets and actions, and add anything else the user asked for in the same arguments ("remind me to…", "also…").

Run this command with the Bash tool, with the note (or the arguments, unchanged) in single quotes (escape any single quote in it as `'\''`):

```
"${CLAUDE_PLUGIN_ROOT}/scripts/note.sh" "${CLAUDE_PLUGIN_DATA}" '<note>'
```

Tell the user what it printed, in one line, or show the notes as printed. If you wrote the note from the session, show it as saved.

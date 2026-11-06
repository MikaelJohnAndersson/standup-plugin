---
description: Show or change the standup plugin's config (repos, orgs, author emails, Linear workspace, retention)
argument-hint: "[the change, in words]"
disable-model-invocation: true
---

Show the config and the repos it includes with the Bash tool:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" "${CLAUDE_PLUGIN_DATA}"
```

With no arguments, show that to the user and stop.

Otherwise make the change the user asked for, `$ARGUMENTS`, to the JSON it printed, and save the whole object in single quotes:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" "${CLAUDE_PLUGIN_DATA}" write '<json>'
```

The keys are `roots`, `orgs`, `include`, `exclude`, `authors`, `linearWorkspace` and `retentionDays`. Paths in `include` and `exclude` cover the folders under them. Tell the user what changed and, if the repos changed, which repos are now included.

# Standup

A [Claude Code](https://code.claude.com) plugin that tells you what you did yesterday. `/standup:summarize` gathers your commits, pull requests, Linear tickets and Claude Code sessions since your last workday, and turns them into a short **Done / Today / To raise** list to say at standup.

## Install

```
/plugin marketplace add MikaelJohnAndersson/standup-plugin
/plugin install standup@standup-plugin
/standup:setup
```

`/standup:setup` scans for git repos (in `~/Documents` unless you name a folder), groups them by GitHub owner, and asks which to include. Sessions are captured from then on.

## Commands

| Command | What it does |
| --- | --- |
| `/standup:summarize [YYYY-MM-DD]` | Summarizes everything since the last workday (Friday on a Monday), or since the given date |
| `/standup:note <text>` | Saves something to raise next time; with no text lists the notes, `clear` clears them |
| `/standup:config [change]` | Shows the config and the repos it includes, or changes it, such as "exclude ~/Documents/www/old-api" |
| `/standup:setup [folder]` | Picks the repos, author emails and Linear workspace |
| `/standup:clear [all]` | Shows what's stored and deletes it once you confirm; `all` deletes the config too |

## Which repos count

A repo is included when its `origin` belongs to one of your chosen GitHub owners, such as your company's orgs, or when it's under an `include` path, and it isn't under an `exclude` path. New repos of a chosen owner are included without setup, so work and personal projects can share a folder.

## Where it looks

- **Git:** your commits on any branch, in the included repos
- **GitHub:** your PRs, and others' you reviewed or commented on, updated in the period (needs `gh`)
- **Linear:** issues assigned to you and the tickets mentioned anywhere above (needs the Linear MCP; skipped without it)
- **Claude Code sessions:** a log written as you work (below)
- **Notes:** what you saved with `/standup:note`

## Session logs

After each turn, a hook appends one line to a daily log: the session title, repo, branch, your prompts (first 200 characters) and the files edited. It's plain `jq`, with no model calls, and only runs in included repos. The model reads the log once, when you summarize.

Logs stay on your machine, in `~/.claude/plugins/data/standup-standup-plugin/`, and are deleted after 14 days (`retentionDays` in the config). Prompts can contain whatever you pasted into a session, so `/standup:clear` is there when you want them gone sooner.

## Requirements

`bash`, `git` and `jq`, on macOS or Linux. `gh` signed in, for pull requests.

## License

[MIT](LICENSE)

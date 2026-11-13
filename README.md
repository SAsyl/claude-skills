# claude-skills

Custom [Claude Code](https://docs.claude.com/en/docs/claude-code) skills and slash commands.

## Contents

| Name | Type | What it does |
|------|------|--------------|
| `publish-repo` | skill (`/publish-repo`) | Publishes a local project as a public GitHub repo: full-history secret scan, MIT license, README, AGENTS.md, CLAUDE.md. |
| `commit` | command (`/commit`) | Creates a commit in Conventional Commits style, English only, no co-author trailers. |

`publish-repo` sets `disable-model-invocation: true`, so it runs only when you type `/publish-repo`.

## Requirements

- Claude Code
- `git`, `bash`, and [`gh`](https://cli.github.com/) for `publish-repo`
- Optional: the GitHub MCP server, and `git-filter-repo` for history rewrites

## Install

Clone the repo, then symlink each item into `~/.claude` so that edits here take effect right away:

```bash
git clone https://github.com/SAsyl/claude-skills.git
cd claude-skills
mkdir -p ~/.claude/skills ~/.claude/commands
for d in skills/*/; do ln -sfn "$PWD/$d" ~/.claude/skills/"$(basename "$d")"; done
for f in commands/*.md; do ln -sf "$PWD/$f" ~/.claude/commands/"$(basename "$f")"; done
```

Restart Claude Code so it picks up the new skills.

## Layout

```
skills/
  publish-repo/
    SKILL.md                 # skill instructions
    scripts/scan_history.sh  # secret / personal data scanner for git history
commands/
  commit.md                  # /commit slash command
```

## Usage

```bash
# Inside Claude Code
/publish-repo ~/path/to/project my-repo
/commit
```

Use the scanner on its own like this:

```bash
bash skills/publish-repo/scripts/scan_history.sh <repo_dir>   # exit 0 = clean, 1 = findings
```

## License

MIT, see [LICENSE](LICENSE).

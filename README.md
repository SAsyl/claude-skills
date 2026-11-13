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

One line, no manual clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/SAsyl/claude-skills/main/install.sh | sh
```

This clones the repo to `~/.local/share/claude-skills` and symlinks every skill and command into `~/.claude`. Run the same line again to update.

From a clone:

```bash
git clone https://github.com/SAsyl/claude-skills.git
cd claude-skills
./install.sh
```

The symlinks point at the clone, so edits there take effect right away. The script stops instead of overwriting a real file or directory in `~/.claude`.

| Variable | Default | Meaning |
|----------|---------|---------|
| `CLAUDE_SKILLS_DIR` | `~/.local/share/claude-skills` | Where the one-line install clones the repo |
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Claude Code config directory |

Restart Claude Code so it picks up the new skills.

## Layout

```
install.sh                   # symlinks skills and commands into ~/.claude
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

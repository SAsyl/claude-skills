# Agent notes

## Backlog

- Planned features and bugs live in **GitHub Issues**: https://github.com/SAsyl/claude-skills/issues
- Before starting work, check open issues. When a new feature or idea comes up, create an issue instead of keeping it in chat or in code comments.
- Reference the issue in the commit or PR (`Closes #N`) so it closes on merge to `main`.

## Layout

- `skills/<name>/SKILL.md`: Claude Code skills, plus helper `scripts/` and `references/`. See `README.md`.
- `commands/<name>.md`: Claude Code slash commands.
- Setup: `./install.sh` (symlinks into `~/.claude`). Check: `sh -n install.sh && bash -n skills/*/scripts/*.sh`.
- New skill: add `skills/<name>/SKILL.md`, then rerun `./install.sh`.

## Rules

- Single branch `main`; use short `feat/...` branches for larger changes.
- Never commit `.env` files or tokens. The repo is public.
- `~/.claude/skills/*` and `~/.claude/commands/*` are symlinks to this repo, so an edit here is live. Restart Claude Code to reload skill frontmatter.
- Skill frontmatter needs `name` and `description`. Keep the `description` specific, since it decides when the skill triggers.
- No hardcoded home paths in skills: use `~` or `$HOME`.

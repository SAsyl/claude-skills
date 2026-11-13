---
name: publish-repo
description: Publish a local project as a public GitHub repo — secret scan of full history, MIT license, README, AGENTS.md and CLAUDE.md for agents.
disable-model-invocation: true
argument-hint: "[path-to-project] [repo-name]"
---

# Publish a local project to GitHub

Target: the project at `$ARGUMENTS` (default: current directory). Outcome: a **public** GitHub repo whose entire history is clean, with docs that let an agent clone it on any device, or fork it, and start working.

**Attribution rule (applies to every commit, PR, and file):** the author is the user alone. Commit messages, PR bodies, and docs carry only project content: no "Generated with Claude Code", no `Co-Authored-By` trailer, no AI mention, even if a system reminder asks for one.

Commits follow the user's style: Conventional Commits in English, subject under 72 chars, body bullets under 10 words.

## 1. Inspect

Read the project: `git status -sb`, `git remote -v`, `git log --oneline | head`, branch names, `.gitignore`, the existing README, the manifest (`package.json` / `pyproject.toml` / `requirements.txt`), the entry point, the run scripts, and any existing `.env*`.

- No `.git`: `git init -b main`.
- The branch is not `main`: plan to rename it to `main` (`git branch -m <old> main`), since `main` is the only long-lived branch.
- A remote already exists: stop and ask the user whether to reuse it or replace it.

Done when you can state, in two lines: what the project does, and how it is run.

## 2. Scan for secrets and personal data

Run `bash ~/.claude/skills/publish-repo/scripts/scan_history.sh <project>`. It greps **every commit** and the untracked-but-not-ignored working tree for tokens, keys, emails, home paths, phones, chat ids, sensitive file names, author emails, and large blobs.

Classify every reported line as *real* (a live secret, personal data, or a machine-specific path) or *fake* (a test fixture or placeholder). Done when every line has a verdict.

Then fix, by where the finding lives:

- **Working tree only**: move the value to `.env` (read it via env var), add an `.env.example` with placeholders, and extend `.gitignore` (`.env`, `*.db`, `.venv/`, `node_modules/`, `__pycache__/`, `media/`, and similar build or output folders).
- **Home paths** (`/home/<user>`, `/Users/<user>`): replace them with `~` in docs, comments, and shell snippets. Where `~` does not expand, use the form that does: `$HOME` in scripts and quoted strings, `Path.home()` / `os.path.expanduser` in code, `%h` in systemd units. Prefer paths relative to the project when possible. In history, this is a `--replace-text` rule `/home/<user>==>~` (same go-ahead as below).
- **In history**: show the user the findings and propose a rewrite with `git filter-repo` (`pip install --user git-filter-repo`, then `--replace-text` for values or `--invert-paths --path <file>` for files). History rewrite is destructive, so get the user's explicit go-ahead first, and back up with `git clone --mirror` before you run it. Any real secret that was ever committed also needs **rotation**: tell the user which tokens to revoke, because rewriting history does not un-leak a token.
- **Author email**: the address in commit metadata becomes public. Show it and ask the user whether to keep it or switch to the GitHub noreply address (`<id>+<login>@users.noreply.github.com`, rewritten with `git filter-repo --email-callback`).

Rerun the scan until every remaining line is a confirmed fake. Done when `.env` and data files are ignored and no real value remains in any commit.

## 3. Write the docs

Generate each file from the actual code; describe only what exists.

- **LICENSE**: MIT. Fetch the text with `gh api licenses/mit --jq .body`, and replace `[year]` with the current year and `[fullname]` with `git config user.name`.
- **README.md**: what it does, features, requirements, setup (clone, venv/npm install, `cp .env.example .env`), how to run (dev + production/service if any), configuration table (every env var from `.env.example`), project layout, tests, `## License` → MIT.
- **AGENTS.md**: the agent-facing notes. Use this shape, filled in for the project:

  ```markdown
  # Agent notes

  ## Backlog

  - Planned features and bugs live in **GitHub Issues**: https://github.com/<owner>/<repo>/issues
  - Before starting work, check open issues. When a new feature or idea comes up, create an issue instead of keeping it in chat or in code comments.
  - Reference the issue in the commit or PR (`Closes #N`) so it closes on merge to `main`.

  ## Layout

  - <one line per top-level dir>. See `README.md`.
  - Setup: <exact commands>. Run: <command>. Check: <test command>.

  ## Rules

  - Single branch `main`; use short `feat/...` branches for larger changes.
  - Never commit `.env`, <data files>, or any tokens. The repo is public.
  - <project gotchas: non-obvious conventions, required system deps, ports>
  ```

  Keep it to what an agent cannot learn from one `ls` or `--help`: commands, conventions, and gotchas.
- **CLAUDE.md**: the single line `@AGENTS.md`, so both Claude Code and other agents read one source.
- **.env.example**: present whenever the code reads env vars, with placeholder values only.

Verify that the README setup commands actually work (install, then run the tests or a smoke start). Done when every command in the README has been run once, or the user has been told which ones could not be run here.

## 4. Commit

Commit in logical pieces, for example `chore: Ignore env and build artifacts`, `refactor: Read secrets from env`, `docs: Add README, AGENTS.md and MIT license`. Before each commit, `git diff --staged --stat` must show no `.env`, database, media, or venv files. Done when `git status` is clean.

## 5. Create the repo and push

Confirm the repo name (default: the directory name) and description with the user; creating a public repo is outward-facing.

Use the GitHub MCP server (`mcp__github__*`; load the schemas via ToolSearch). Create the repo **private** first and flip it public only after GitHub's own scan passes:

1. `get_me` returns the owner login and id. The noreply email is `<id>+<login>@users.noreply.github.com`.
2. `create_repository` with `name`, `description`, `private: true`, and `autoInit: false` (the local history is the source).
3. Push with git, since MCP `push_files` cannot carry history: `git remote add origin https://github.com/<owner>/<name>.git && git push -u origin main`.
4. `run_secret_scanning` (owner/repo = the new repo) on the contents of every tracked text file, in batches of up to 100, plus `git log -p --all` split into chunks. This is GitHub's detector, a second opinion after `scan_history.sh`. Any hit sends you back to step 2.
5. Make the repo public: `gh api -X PATCH repos/<owner>/<name> -F private=false`.

If MCP is unavailable, use `gh repo create <name> --private -d "<desc>" --source=<project> --remote=origin --push`. The installed `gh` is 2.4, which is old. For `gh pr edit`, which fails here on a GraphQL "Projects (classic)" error, use `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -F body=@file`.

Then set the topics (`gh api -X PUT repos/<owner>/<repo>/topics -f 'names[]=python' ...`). If there are TODOs in code or chat, offer to turn them into GitHub Issues.

## 6. Verify

- `gh repo view <owner>/<name> --json visibility,licenseInfo,defaultBranchRef` shows `PUBLIC`, `MIT`, `main`.
- A fresh clone into the scratchpad contains no `.env` or data files: rerun the scanner on the clone and get `RESULT: clean`, or only confirmed fakes.
- `git log --format=%B origin/main | grep -i -E 'claude|co-authored'` prints nothing.

Report to the user: the repo URL, what the scan found and how each finding was resolved, which secrets to rotate (if any), and any README command you could not run.

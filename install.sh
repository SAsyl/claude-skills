#!/bin/sh
# Install the skills and commands from this repo into ~/.claude as symlinks.
# Local:  ./install.sh
# Remote: curl -fsSL https://raw.githubusercontent.com/SAsyl/claude-skills/main/install.sh | sh
set -eu

REPO_URL="https://github.com/SAsyl/claude-skills.git"
CLONE_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.local/share/claude-skills}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

# Use the repo the script lives in; otherwise clone or update it in CLONE_DIR
resolve_repo() {
  script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
  if [ -n "$script_dir" ] && [ -f "$script_dir/install.sh" ] && [ -d "$script_dir/skills" ]; then
    printf '%s\n' "$script_dir"
    return
  fi
  command -v git >/dev/null 2>&1 || die "git is required"
  if [ -d "$CLONE_DIR/.git" ]; then
    git -C "$CLONE_DIR" pull --ff-only --quiet >&2 || die "cannot update $CLONE_DIR"
  elif [ -e "$CLONE_DIR" ]; then
    die "$CLONE_DIR exists and is not a git repo"
  else
    git clone --quiet "$REPO_URL" "$CLONE_DIR" >&2 || die "cannot clone $REPO_URL"
  fi
  printf '%s\n' "$CLONE_DIR"
}

# Symlink src to dest; refuse to overwrite a real file or directory
link() {
  src=$1
  dest=$2
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    die "$dest exists and is not a symlink; move it away and rerun"
  fi
  ln -sfn "$src" "$dest"
  printf '  %s -> %s\n' "$dest" "$src"
}

main() {
  repo=$(resolve_repo)
  mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/commands"

  echo "Skills:"
  for dir in "$repo"/skills/*/; do
    [ -f "$dir/SKILL.md" ] || continue
    name=$(basename "$dir")
    link "$repo/skills/$name" "$CLAUDE_DIR/skills/$name"
  done

  echo "Commands:"
  for file in "$repo"/commands/*.md; do
    [ -f "$file" ] || continue
    link "$file" "$CLAUDE_DIR/commands/$(basename "$file")"
  done

  echo "Done. Restart Claude Code to load new skills."
}

main

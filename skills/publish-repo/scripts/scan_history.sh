#!/usr/bin/env bash
# Scan a git repo (all history + current working tree) for secrets and personal data.
# Usage: scan_history.sh [repo_dir]. Exit 0 = clean, 1 = findings to review.
set -euo pipefail

repo="${1:-.}"
cd "$repo"
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: $repo is not a git repo" >&2; exit 2; }

found=0
section() { printf '\n== %s ==\n' "$1"; }
report() { if [ -n "$1" ]; then printf '%s\n' "$1"; found=1; else echo "(none)"; fi; }

secret_re='AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{20,}'
secret_re+='|[0-9]{8,10}:AA[A-Za-z0-9_-]{33}|sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9_-]{32,}'
secret_re+='|AIza[0-9A-Za-z_-]{35}|xox[abprs]-[A-Za-z0-9-]{10,}|hf_[A-Za-z0-9]{30,}'
secret_re+='|-----BEGIN [A-Z ]*PRIVATE KEY-----'
secret_re+='|(api[_-]?key|secret|token|passw(or)?d|bearer)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{8,}'

personal_re='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|/home/[a-z_][a-z0-9_-]*|/Users/[A-Za-z0-9_-]+'
personal_re+='|\+?[0-9]{1,3}[ (-]*[0-9]{3}[ )-]*[0-9]{3}[ -]?[0-9]{2}[ -]?[0-9]{2}|-100[0-9]{10}'

bad_files_re='(^|/)(\.env(\.[^/]*)?|id_(rsa|ed25519|ecdsa)[^/]*|[^/]*\.(pem|key|p12|pfx|keystore|jks|db|sqlite3?|session)'
bad_files_re+='|credentials[^/]*|[^/]*secret[^/]*|[^/]*token[^/]*|service[-_]account[^/]*\.json|config\.json|\.npmrc|\.pypirc|\.netrc)$'

skip_paths=(':!*.lock' ':!package-lock.json' ':!*.min.js' ':!*.map' ':!node_modules' ':!.venv')

# grep every commit plus the working tree (tracked + untracked, not ignored); print unique path:line:match
grep_all() {
  local re="$1"
  local revs=()
  mapfile -t revs < <(git rev-list --all)
  {
    local i
    for ((i = 0; i < ${#revs[@]}; i += 50)); do
      git grep -I -n -o -i -E "$re" "${revs[@]:i:50}" -- . "${skip_paths[@]}" 2>/dev/null | cut -d: -f2- || true
    done
    git grep -I -n -o -i -E --untracked "$re" -- . "${skip_paths[@]}" 2>/dev/null || true
  } | sort -u
}

section "Secrets and tokens (history + working tree)"
report "$(grep_all "$secret_re" | grep -v -i -E 'example|placeholder|your[_-]|xxx|<[a-z_]+>|changeme|dummy|fake|test' || true)"

section "Possible secrets with test/example markers (verify they are fake)"
report "$(grep_all "$secret_re" | grep -i -E 'example|placeholder|your[_-]|xxx|<[a-z_]+>|changeme|dummy|fake|test' || true)"

section "Personal data: emails, home paths, phones, chat ids"
report "$(grep_all "$personal_re" | grep -v -E 'noreply|example\.(com|org)|@users\.noreply\.github\.com' || true)"

section "Sensitive file names ever committed"
report "$(git log --all --pretty=format: --name-only | sort -u | grep -E "$bad_files_re" | grep -v -E '\.example$|\.sample$|\.template$' || true)"

section "Sensitive files present now and NOT ignored"
report "$(git ls-files -co --exclude-standard | grep -E "$bad_files_re" | grep -v -E '\.example$|\.sample$|\.template$' || true)"

section "Commit authors (emails become public on push)"
git log --all --format='%an <%ae>' | sort -u || true
git log --all --format='%cn <%ce>' | sort -u | sed 's/^/committer: /' || true

section "Large blobs in history (>5 MB)"
report "$(git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' \
  | awk '$1=="blob" && $2>5242880 {printf "%.1f MB %s\n", $2/1048576, $3}' || true)"

echo
if [ "$found" -eq 0 ]; then echo "RESULT: clean"; else echo "RESULT: findings — review every line above"; fi
exit "$found"

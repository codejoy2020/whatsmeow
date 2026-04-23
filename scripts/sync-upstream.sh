#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/tulir/whatsmeow.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"

cd "$REPO_ROOT"

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "[sync-upstream] remote 'upstream' not found, adding: $UPSTREAM_URL"
  git remote add upstream "$UPSTREAM_URL"
fi

echo "[sync-upstream] fetching upstream"
git fetch upstream

echo "[sync-upstream] merging upstream/${UPSTREAM_BRANCH} into $(git branch --show-current)"
if ! git merge "upstream/${UPSTREAM_BRANCH}"; then
  echo "[sync-upstream] merge conflict detected. Resolve conflicts, then continue."
  exit 1
fi

echo "[sync-upstream] done"

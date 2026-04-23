#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"

cd "$REPO_ROOT"

BRANCH="$(git branch --show-current)"
if [[ -z "$BRANCH" ]]; then
  echo "[push-fork] unable to detect current branch"
  exit 1
fi

echo "[push-fork] pushing $BRANCH to $ORIGIN_REMOTE"
git push "$ORIGIN_REMOTE" "$BRANCH"

if [[ "${1:-}" == "--tags" ]]; then
  echo "[push-fork] pushing tags to $ORIGIN_REMOTE"
  git push "$ORIGIN_REMOTE" --tags
fi

echo "[push-fork] done"

#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <repo_name> '<commit message>'"
  exit 1
fi

REPO_NAME="$1"
COMMIT_MSG="$2"

AUTHOR_NAME="iaboudou"
AUTHOR_EMAIL="ilyassaboudou07@gmail.com"

GITHUB_REPO="https://github.com/iaboudou/${REPO_NAME}.git"
GITEA_REPO="https://learn.zone01oujda.ma/git/iaboudou/${REPO_NAME}.git"

BRANCH="${BRANCH:-main}"

# helper
set_remote() {
  local name="$1" url="$2" curr
  curr=$(git remote get-url "$name" 2>/dev/null || true)
  if [ -z "$curr" ]; then
    git remote add "$name" "$url"
  elif [ "$curr" != "$url" ]; then
    git remote set-url "$name" "$url"
  fi
}

git config --global credential.helper store || true
[ -d .git ] || git init

# ensure branch
git checkout -B "$BRANCH"

# commit if changes
if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "$COMMIT_MSG" --author="$AUTHOR_NAME <$AUTHOR_EMAIL>"
  echo "✅ Committed as $AUTHOR_NAME <$AUTHOR_EMAIL>"
else
  echo "ℹ️ No changes to commit"
fi

# configure remotes
set_remote github "$GITHUB_REPO"
set_remote gitea "$GITEA_REPO"

# force push both
git push --force github "HEAD:$BRANCH"
git push --force gitea "HEAD:$BRANCH"

echo "Done✅"
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

# helper to add/set remote
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

# commit if changes (use fixed author)
if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "$COMMIT_MSG" --author="$AUTHOR_NAME <$AUTHOR_EMAIL>"
  echo "✅ Committed as $AUTHOR_NAME <$AUTHOR_EMAIL>"
else
  echo "ℹ️ No changes to commit"
fi

# configure remotes (add or update)
set_remote github "$GITHUB_REPO"
set_remote gitea "$GITEA_REPO"

# function to attempt push and continue on error
attempt_push() {
  local remote_name="$1"
  local remote_url="$2"
  local branch_ref="$3"

  echo "-> Pushing (force) to ${remote_name} (${remote_url}) ..."
  set +e
  git push --force "$remote_name" "$branch_ref"
  rc=$?
  set -e

  if [ $rc -ne 0 ]; then
    echo "⚠️ Push to ${remote_name} failed (rc=$rc). Continuing..."
    return 1
  else
    echo "✅ Forced push to ${remote_name} done."
    return 0
  fi
}

# try GitHub push first (don't fail whole script if it errors)
attempt_push "github" "$GITHUB_REPO" "HEAD:$BRANCH" || true

# try Gitea push, skip if unreachable or error
attempt_push "gitea" "$GITEA_REPO" "HEAD:$BRANCH" || true

echo "Finished. (script exits normally even if one push failed)"

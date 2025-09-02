#!/bin/bash
set -euo pipefail

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"

BRANCH_NAME=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
echo "Branch name: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"
git add .

if git diff --staged --quiet; then
    echo "No changes to commit"
    exit 0
fi

git commit -m "$DESCRIPTION"
git push origin "$BRANCH_NAME"

gh pr create \
    --title "$DESCRIPTION" \
    --body "$DESCRIPTION" \
    --base main \
    --head "$BRANCH_NAME"

echo "Successfully created branch '$BRANCH_NAME' and pull request"

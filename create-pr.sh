#!/bin/bash
set -euo pipefail

case "${SOURCE_ENV}" in
    dev)  TARGET_ENV="uat"  ;;
    uat)  TARGET_ENV="prod" ;;
esac

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git checkout env/$TARGET_ENV

BRANCH_NAME=feat/$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
echo "Branch name: $BRANCH_NAME"
git checkout -B "$BRANCH_NAME"
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
    --base "env/$TARGET_ENV" \
    --head "$BRANCH_NAME"

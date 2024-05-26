#!/bin/bash
gh --repo "${1}" pr checkout "${2}" || return
base_commit=$(gh pr list --repo "${1}" --search "${2}" --json commits | jq -e -r .[0].commits[0].oid)
if [ $? -eq 0 ]; then
	git tag --delete PR_BASE_COMMIT 2> /dev/null
	git tag "PR_BASE_COMMIT" "$base_commit"
fi


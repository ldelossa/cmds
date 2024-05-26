#!/bin/bash

echo "Will show diffs for the following files"
echo ""
git show --pretty=format: --name-only "$1"
echo ""
echo "Hit any key to continue, <ctrl-c> to cancel."
read -r
git show --pretty=format: --name-only "$1" | xargs -I{} git diff "$1":{} "$2":{}


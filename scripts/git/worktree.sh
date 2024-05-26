#!/bin/bash

git worktree add ../worktree-"${1}" --checkout "$1" && cd ../worktree-"${1}" || exit
if [[ -z ${2} ]]; then
	zsh
else
	nvim "${2}"
fi
cd - || exit
git worktree remove ../worktree-"${1}"

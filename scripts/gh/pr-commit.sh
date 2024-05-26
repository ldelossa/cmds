#!/bin/bash
number=$(gh api repos/${1}/commits/${2}/pulls | jq .[].number)
[[ -z $number ]] && echo "No PR exists for commit" && return
gh --repo ${1} pr view $number


#!/bin/bash

function log() {
	echo -e ""
	echo -e "\e[34m${1}\e[0m"
	echo -e ""
}

review_commit() {
	log "Stopping to review commit:"
	git log -1 --format=short
	log "Use ctrl-c to cancel iteration, ctrl-z to access terminal, any-key to continue iteration."
	read -r
}

export -f log
export -f review_commit

git rebase --exec="bash -c review_commit" "${1}"


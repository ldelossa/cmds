#!/bin/bash

IFS=$'\n'

entries=($(cat /etc/hosts))

sanitized=()

for entry in "${entries[@]}"; do
	if [[ -z $entry ]]; then
		continue
	fi
	if [[ ${entry:0:1} == "#" ]]; then
		continue
	fi
	sanitized+=("$entry")
done

for ((i=0; i<${#sanitized[@]}; i++)); do
	echo "$i: ${sanitized[$i]}"
done

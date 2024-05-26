#!/bin/bash

dest_host="${1}"
from="${2}"
to="${3}"

if [[ -z "${3}" ]]; then
	to="${2}"
fi

rsync -avz --progress -e ssh "$from" "$dest_host":"$to"

#!/bin/bash

file="${1}"

if [ -z "${file}" ]; then
  exit 1
fi

git log --diff-filter=A -- "${file}"

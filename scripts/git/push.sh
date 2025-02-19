#!/bin/bash

remote=${1}
local_branch=${2}
remote_branch=${3}

git push "${remote}" "${local_branch}":"${remote_branch}"

#!/bin/bash

host=${1}
user=${2}

ssh_host="${user}@${host}"
repo=$(pwd)

function log() {
	echo -e ""
	echo -e "\e[34m${1}\e[0m"
}

# push local repository to remote.
log "Pushing local repository to remote..."
ssh "${ssh_host}" "mkdir -p $repo || true"
rsync -e ssh --delete --exclude '.git' -azv "$repo"/ "${ssh_host}":"$repo"

log "Creating config based on current modules"
ssh "${ssh_host}" "cd $repo && lsmod > mods.now && yes '' | make LSMOD=mods.now localmodconfig"

log "Applying common configuration edits"
# 1. don't randomize address spaces making the kernel a bit easier to debug
# 2. delete the trusted keys for signing, forcing `make install` to prompt us
#    for the desired value (usually blank string).
ssh ${ssh_host} "cd $(pwd) && \
				 sed -i 's/^\\(CONFIG_RANDOMIZE_BASE\\)=y/# \\1 is not set/' .config && \
				 sed -i '/^CONFIG_SYSTEM_TRUSTED_KEYS=.*$/d' .config"

log "Syncing remote repository to local..."
rsync -e ssh --delete -azv "${ssh_host}":"$repo"/ "$repo"/

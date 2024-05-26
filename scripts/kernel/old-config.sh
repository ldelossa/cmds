#!/bin/bash

set -e

host=${1}
user=${2}

ssh_host="${user}@${host}"

function log() {
	echo -e ""
	echo -e "\e[34m${1}\e[0m"
}

# push local repository to remote.
log "Pushing local repository to remote..."
ssh "${ssh_host}" "mkdir -p $(pwd) || true"

rsync -e ssh --delete -azv "$(pwd)"/ ${ssh_host}:"$(pwd)"

log "Copying existing config file to local repository..."
ssh "${ssh_host}" "cd $(pwd) && cp /boot/config-\$(uname -r) .config"

log "Making new config..."
ssh "${ssh_host}" "cd $(pwd) && yes '' | make olddefconfig"

log "Applying common configuration edits"
# 1. don't randomize address spaces making the kernel a bit easier to debug
# 2. delete the trusted keys for signing, forcing `make install` to prompt us
#    for the desired value (usually blank string).
ssh ${ssh_host} "cd $(pwd) && \
				 sed -i 's/^\\(CONFIG_RANDOMIZE_BASE\\)=y/# \\1 is not set/' .config && \
				 sed -i '/^CONFIG_SYSTEM_TRUSTED_KEYS=.*$/d' .config"

log "Syncing remote repository to local..."
rsync -e ssh --delete -azv "${ssh_host}":"$(pwd)"/ "$(pwd)"/

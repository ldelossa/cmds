#!/bin/bash

# stop if errors
set -e

host=${1}
user=${2}
reboot=${3}
root="root"

ssh_host="${user}@${host}"
root_ssh_host="${root}@${host}"
kernel_version=$(make kernelversion)
repo=$(pwd)

function log() {
	echo -e ""
	echo -e "\e[34m${1}\e[0m"
}

# push local repository to remote.
log "Pushing local repository to remote..."
ssh "${ssh_host}" "mkdir -p $repo || true"
rsync -e ssh --delete --exclude '.git' -azv "$repo"/ "${ssh_host}":"$repo"

log "Building the remote kernel..."
ssh "${ssh_host}" "cd $repo && make -j \$((\$(nproc)*2)) && make tools/lib/bpf && make tools/bpf/bpftool && ./scripts/clang-tools/gen_compile_commands.py"

log "Installing the remote Kernel..."
ssh "${root_ssh_host}" "cd $repo && make modules_install && make install"

log "Installing libbpf from kernel tree..."
# make the library
ssh "${ssh_host}" "cd $repo/tools/lib/bpf && make"
# backup any existing libbpf libraries
ssh "${root_ssh_host}" "mv /usr/lib64/libbpf* /tmp || true"
# install libbpf to /usr/lib64 (fedora specific)
ssh "${root_ssh_host}" "cd $repo/tools/lib/bpf && make prefix=/usr install && cp libbpf.so* /usr/lib64/ && chown -R ${user}:${user} ."

log "Installing bpftool from kernel tree..."
ssh "${root_ssh_host}" "cd $repo/tools/bpf/bpftool && make install && chown -R ${user}:${user} ."

log "Resetting all file perms to user..."
ssh "${root_ssh_host}" "cd $repo && chown -R ${user}:${user} ."

log "Syncing built kernel locally..."
rsync -e ssh --delete --exclude '.git' -azv "${ssh_host}":"$repo"/ "$repo"/

if [[ -n $reboot ]]; then
	log "Install complete, rebooting the host..."
	ssh "${root_ssh_host}" "reboot"
else
	log "Install complete, reboot the host to enter new kernel..."
fi

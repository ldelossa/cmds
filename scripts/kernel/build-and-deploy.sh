#!/bin/bash

host=${1}
user=${2}
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
rsync -e ssh --delete -azv "$repo"/ "${ssh_host}":"$repo"

log "Building the remote kernel..."
ssh "${ssh_host}" "cd $repo && make -j \$((\$(nproc)*2)) && make tools/lib/bpf && make tools/bpf/bpftool && ./scripts/clang-tools/gen_compile_commands.py"

log "Installing the remote Kernel..."
# systemd tries to auto-load modules during early boot.
# however, if the new kernel embeds a previously module this can break the boot
# we can blow away these auto-loads and modprobe can figure it out.
# see "man systemd-modules-load"
ssh "${root_ssh_host}" "rm -rf /etc/modules-load.d/*.conf || true; \
					  	rm -rf /run/modules-load.d/*.conf || true; \
					  	rm -rf /usr/lib/modules-load.d/*conf || true "
ssh "${root_ssh_host}" "cd $repo && make modules_install && make install"
# perform our own dracut call just incase make install does not do it properly
ssh "${root_ssh_host}" "dracut -f /boot/initramfs-$kernel_version.img $kernel_version"
# its possible that grub is setup using pre-BLS configuration.
# in this case, we can proactively make the symlinks we need just incase
# the grub config still utilizes them.
ssh "${root_ssh_host}" "unlink /boot/initrd && true && \
						unlink /boot/vmlinuz && true && \
						ln -s /boot/vmlinuz-$kernel_version /boot/vmlinuz && \
						ln -s /boot/initramfs-$kernel_version.img /boot/initrd"

log "Installing libbpf from kernel tree..."
# make the library
ssh "${ssh_host}" "cd $repo/tools/lib/bpf && make"
# backup any existing libbpf libraries
ssh "${root_ssh_host}" "mv /usr/lib64/libbpf* /tmp || true"
# install libbpf to /usr/lib64 (fedora specific)
ssh "${root_ssh_host}" "cd $repo/tools/lib/bpf && make prefix=/usr install && cp libbpf.so* /usr/lib64/ && chown -R ${user}:${user} ."

log "Installing bpftool from kernel tree..."
ssh "${root_ssh_host}" "cd $repo/tools/bpf/bpftool && make install && chown -R ${user}:${user} ."

log "Syncing built kernel locally..."
rsync -e ssh --delete -azv "${ssh_host}":"$repo"/ "$repo"/

log "Install complete, reboot the host to enter new kernel..."

#!/bin/bash

host=${1}
user=${2}

function log() {
	echo -e ""
	echo -e "\e[34m${1}\e[0m"
}

# qemu and kvm install
sudo dnf groupinstall -y virtualization

# assuming root login first, bootstrap our user, will be prompted for visudo
# and password update.
log "Configuring user ${user}..."
ssh root@"${host}" "useradd ${user} || true && cp -r ~/.ssh /home/${user}/ && chown -R ${user}:${user} /home/louis"
ssh root@"${host}" "echo '${user} ALL=(ALL) ALL' >> /etc/sudoers"
ssh root@"${host}" "passwd ${user}"

# zellij > tmux
ssh root@"${host}" "dnf -y copr enable varlad/zellij"
# neovim nightly
ssh root@"${host}" "dnf -y copr enable agriffis/neovim-nightly"
# containerlab repo
ssh root@"${host}" "dnf config-manager --add-repo=https://yum.fury.io/netdevops/ && \
					echo 'gpgcheck=0' | sudo tee -a /etc/yum.repos.d/yum.fury.io_netdevops_.repo"

# install server packages
log "Installing server packages..."
ssh root@"${host}" "dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm \
					https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
ssh root@"${host}" "dnf install -y bat bear clang clang-tools-extra exa fd-find 	\
				  	fuse-sshfs fzf htop jq nmap the_silver_searcher zsh  		  	\
				  	rust pam-devel nnn scdoc meson flex bison procs npm 		  	\
				  	llvm-devel gdb kitty elfutils-libelf-devel openssl-devel 	  	\
				  	dwarves zstd wireshark ripgrep ncurses-devel moby-engine	  	\
				  	util-linux-user git lld python3-docutils strace difftastic  	\
				  	libbpf bc compat-lua-libs libtermkey libtree-sitter tcpdump	  	\
				  	libvterm luajit luajit2.1-luv msgpack unibilium xsel rpm-build  \
					perl gh bpftrace zellij et neovim containerlab btop rsync nasm  \
					glibc-static glibc-devel"

# configure docker
log "Enabling docker (moby-agent)..."
ssh root@"${host}" "systemctl enable docker && systemctl start docker"

# install golang
log "Installing golang..."
ssh root@"${host}" "cd /tmp && git clone https://github.com/udhos/update-golang.git \
				  	&& cd update-golang && ./update-golang.sh"

# install kind
log "Installing kind..."
ssh root@"${host}" "cd /tmp && \
				 	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && \
				 	chmod +x ./kind && \
				 	sudo mv ./kind /usr/local/bin"

# install kubectl
log "Installing kubectl..."
ssh root@"${host}" "dnf config-manager --add-repo=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/ && 	  \
				  	rpm --import https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key && \
				  	dnf install -y kubectl"

# install k9s
log "Installing k9s..."
ssh root@"${host}" "cd /tmp  &&							\
				  	curl -LO https://github.com/derailed/k9s/releases/download/v0.32.4/k9s_Linux_amd64.tar.gz && \
				  	tar -xvf k9s_Linux_amd64.tar.gz &&    \
				  	chmod +x ./k9s &&						\
				  	sudo mv ./k9s /usr/local/bin	&&		\
				  	rm -rf k9s_Linux_amd64.tar.gz"

# install helm
log "Installing helm..."
ssh root@"${host}" "cd /tmp && \
				  	curl -LO https://get.helm.sh/helm-v3.15.1-linux-amd64.tar.gz && \
				  	tar -xvf helm-v3.15.1-linux-amd64.tar.gz && \
				  	chmod +x ./linux-amd64/helm && \
				  	sudo mv ./linux-amd64/helm /usr/local/bin && \
				  	rm -rf helm-v3.8.0-linux-amd64.tar.gz"

# add user to appropriate groups
log "Adding user to docker and wheel groups..."
ssh root@"${host}" "usermod -a ${user} -G docker && \
				  	usermod -a ${user} -G wheel"

# setup buildx plugin for docker
log "Setting up docker buildx plugin..."
ssh "${user}"@"${host}" "cd /tmp && \
					 	mkdir -p ~/.docker/cli-plugins && \
					 	cd ~/.docker/cli-plugins && \
					 	curl -LO https://github.com/docker/buildx/releases/download/v0.14.1/buildx-v0.14.1.linux-amd64 && \
					 	mv buildx* docker-buildx && \
					 	chmod u+x docker-buildx"

# setup common code dirs
log "Setting up common code directories..."
ssh "${user}"@"${host}" "mkdir ~/git || true		\
					 	mkdir ~/git/go || true		\
					 	mkdir ~/git/c 	|| true"

# configure dotfiles
log "Configuring dotfiles..."
ssh "${user}"@"${host}" "cd ~/git && 											\
					 	mkdir ~/.config || true &&								\
					 	git clone https://github.com/ldelossa/dotfiles &&   	\
					 	cd dotfiles && 										\
					 	make all"

# setup slimzsh
log "Setting up slimzsh..."
ssh "${user}"@"${host}" "git clone --recursive https://github.com/changs/slimzsh.git ~/.slimzsh && chsh -s /usr/bin/zsh"

# setup fzf
log "Setting up fzf..."
ssh "${user}"@"${host}" "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
					 ~/.fzf/install --key-bindings --completion --update-rc"

log "Installing  gopls..."
ssh "${user}"@"${host}" "/usr/local/go/bin/go install golang.org/x/tools/gopls@latest"

log "Installing dlv"
ssh "${user}"@"${host}" "/usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest"

# configure sysctls
log "Configuring sysctls..."
ssh root@"${host}" "echo 'fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-arptables = 0' > /etc/sysctl.conf && sysctl -p"

# configuring root user, leave dotfiles make till end, since it may return an
# exit code despite everything being okay.
log "Configuring root user..."
ssh root@"${host}" "mkdir -p /root/git && cp -R /home/louis/git/dotfiles /root/git/dotfiles && \
					cp -R /home/louis/.slimzsh /root/.slimzsh && \
					cp -R /home/louis/.fzf/ /root/.fzf && cp /home/louis/.fzf.zsh /root/.fzf.zsh && \
					make -C /root/git/dotfiles all"

log "Setup complete"

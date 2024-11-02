# server side script which runs on the server being configured

function log() {
	echo -e ""
	echo -e "\e[34m${1}\e[0m"
}

log "Installing packages..."
sudo dnf config-manager --add-repo=https://yum.fury.io/netdevops/ && \
	echo 'gpgcheck=0' | sudo tee -a /etc/yum.repos.d/yum.fury.io_netdevops_.repo

sudo dnf install -y epel-release && sudo dnf config-manager --set-enabled crb

sudo dnf install -y bat bear clang clang-tools-extra exa fd-find fuse-sshfs \
					htop jq nmap the_silver_searcher zsh rust pam-devel nnn scdoc meson flex bison \
					procs npm llvm-devel gdb elfutils-libelf-devel openssl-devel dwarves zstd \
					wireshark ripgrep ncurses-devel util-linux-user git lld python3-docutils strace \
					difftastic libbpf bc compat-lua-libs libtermkey libtree-sitter libvterm luajit \
					luajit2.1-luv msgpack unibilium xsel rpm-build perl tmux containerlab rsync tcpdump \
					btop et bpftrace nasm glibc-static glibc-devel qemu-kvm libvirt virt-manager \
					virt-install kitty-terminfo

# install container-lab
sudo dnf config-manager --add-repo=https://yum.fury.io/netdevops/ && \
echo "gpgcheck=0" | sudo tee -a /etc/yum.repos.d/yum.fury.io_netdevops_.repo
sudo dnf install -y containerlab

# Install neovim
log "Installing neovim..."
cd /tmp && \
curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz && \
sudo tar xvzf nvim-linux64.tar.gz -C /usr/share && \
sudo ln -s /usr/share/nvim-linux64/bin/nvim /usr/local/bin

log "Installing zellij.."
cd /tmp && \
curl -LO https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz && \
tar -xvf zellij-x86_64-unknown-linux-musl.tar.gz && \
sudo mv zellij /usr/local/bin

# install docker
log "Installing docker..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
sudo dnf -y install docker-ce docker-ce-cli containerd.io && \
sudo systemctl enable docker && systemctl start docker

# install golang
log "Installing golang..."
cd /tmp && git clone https://github.com/udhos/update-golang.git \
&& cd update-golang && sudo ./update-golang.sh
# install gopls
/usr/local/go/bin/go install golang.org/x/tools/gopls@latest
# install dlv
/usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest

# install kind
log "Installing kind..."
cd /tmp && \
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && \
chmod +x ./kind && \
sudo mv ./kind /usr/local/bin

# install kubectl
log "Installing kubectl..."
sudo dnf config-manager --add-repo=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/ && 	  \
sudo rpm --import https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key && \
sudo dnf install -y kubectl

# install k9s
log "Installing k9s..."
cd /tmp  &&							\
curl -LO https://github.com/derailed/k9s/releases/download/v0.32.4/k9s_Linux_amd64.tar.gz && \
tar -xvf k9s_Linux_amd64.tar.gz &&    \
chmod +x ./k9s &&						\
sudo mv ./k9s /usr/local/bin	&&		\
rm -rf k9s_Linux_amd64.tar.gz

# install helm
log "Installing helm..."
cd /tmp && \
curl -LO https://get.helm.sh/helm-v3.15.1-linux-amd64.tar.gz && \
tar -xvf helm-v3.15.1-linux-amd64.tar.gz && \
chmod +x ./linux-amd64/helm && \
sudo mv ./linux-amd64/helm /usr/local/bin && \
rm -rf helm-v3.8.0-linux-amd64.tar.gz

# git repos
mkdir ~/git
mkdir ~/git/go
mkdir ~/git/c
mkdir ~/git/lua

# fzf
log "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --update-rc

# slimzsh
log "Installing slimzsh"
git clone --recursive https://github.com/changs/slimzsh.git ~/.slimzsh

# docker zsh completion (doesn't ship with moby package)
curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > /tmp/_docker
sudo mv /tmp/_docker /usr/share/zsh/site-functions

# docker buildx install
cd /tmp || exit
mkdir -p ~/.docker/cli-plugins
cd ~/.docker/cli-plugins || exit
curl -LO https://github.com/docker/buildx/releases/download/v0.18.0/buildx-v0.18.0.linux-amd64
mv buildx* docker-buildx
chmod u+x docker-buildx

## setup lua language server
cd ~/git/lua || exit
curl -LO https://github.com/LuaLS/lua-language-server/releases/download/3.6.11/lua-language-server-3.6.11-linux-x64.tar.gz
mkdir lua-language-server
tar -xvf lua-language-server-3.6.11-linux-x64.tar.gz -C lua-language-server
rm -rf lua-language-server-3.6.11-linux-x64.tar.gz
cd /tmp || exit

## setup vscode extracted lsps
sudo npm install -g vscode-langservers-extracted

## setup yaml language server
sudo npm install -g yaml-language-server

## setup bash language server
sudo npm install -g vim-language-server

# chatblade, shell-gpt, and b4 (python)
pip install chatblade b4 shell-gpt --upgrade

# add user to appropriate groups
log "Configuring user groups..."
sudo usermod -a "$(whoami)" -G docker
sudo usermod -a "$(whoami)" -G wheel
sudo usermod -a "$(whoami)" -G libvirt

# setup sysctls
log "Configuring sysctls..."
sudo echo 'fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-arptables = 0' | sudo tee /etc/sysctl.conf && sysctl -p

# services setup
log "Configuring services"
sudo systemctl disable firewalld
sudo systemctl stop firewalld

sudo systemctl enable libvirtd
sudo systemctl start libvirtd

sudo systemctl start docker
sudo systemctl enable docker

## setup dotfiles
log "Deploying dotfiles..."
cd ~/git || exit
mkdir ~/.config
git clone https://github.com/ldelossa/dotfiles
cd dotfiles || exit
git remote remove origin
git remote add origin git@github.com:ldelossa/dotfiles
make all
# special step here to avoid kitty.conf being checked into git
echo 'include kitty_include.conf' > ~/.config/kitty/kitty.conf
cd /tmp || exit

# change shell
log "Changing shell to zsh..."
sudo chsh -s /bin/zsh "$(whoami)"

log "Deploying dotfiles for root..."
# configuring root user, leave dotfiles make till end, since it may return an
# exit code despite everything being okay.
sudo mkdir -p /root/git && sudo cp -R $HOME/git/dotfiles /root/git/dotfiles && \
sudo cp -R $HOME/.slimzsh /root/.slimzsh && \
sudo cp -R $HOME/.fzf/ /root/.fzf && sudo cp $HOME/.fzf.zsh /root/.fzf.zsh && \
sudo make -C /root/git/dotfiles all

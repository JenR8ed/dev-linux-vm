#!/usr/bin/env bash

set -oue pipefail

# Update system packages and install essentials in one transaction
dnf update -y && \
dnf install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    tmux \
    nodejs \
    npm \
    python3 \
    python3-pip \
    docker \
    podman \
    make \
    gcc \
    g++ \
    openssh-server \
    rsync

# Install GitHub CLI
dnf install -y 'dnf-command(config-manager)' && \
curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo | tee /etc/yum.repos.d/gh-cli.repo && \
dnf install -y gh

# Install additional web development tools
# Skip npm for now due to permission issues in container build
# npm install -g \
#     @angular/cli \
#     @vue/cli \
#     create-react-app \
#     typescript \
#     eslint \
#     prettier

# Python development tools
# Create /usr/local/lib directory for pip installations
if [ -L /usr/local ]; then
    # Create the target directory for the symlink
    mkdir -p /var/usrlocal/lib/python3.13/site-packages
else
    mkdir -p /usr/local/lib/python3.13/site-packages
fi
pip3 install \
    flask \
    django \
    fastapi \
    virtualenv

# Configure SSH for X11 forwarding
mkdir -p /etc/ssh/sshd_config.d/
cat > /etc/ssh/sshd_config.d/99-x11-forwarding.conf << EOF
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
EOF

# Create development user
useradd -m -G wheel developer
echo "developer:developer" | chpasswd

# Configure Git aliases
cat > /etc/skel/.gitconfig << EOF
[user]
    name = Developer
    email = developer@localhost
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --all
[init]
    defaultBranch = main
EOF

# Create useful development aliases
cat > /etc/skel/.bashrc << 'EOF'
# Development aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Development shortcuts
alias serve='python3 -m http.server'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# X11 forwarding helper
export DISPLAY=${DISPLAY:-:10.0}

# Development PATH
export PATH="$HOME/.local/bin:$PATH"
EOF

# Create development directories
# Fix broken /opt symlink in Universal Blue base image
# /opt -> var/opt but /var/opt doesn't exist
if [ -L /opt ]; then
    mkdir -p /var/opt/dev-tools
else
    mkdir -p /opt/dev-tools
fi
mkdir -p /home/developer/{projects,scripts,tools}

# Clean up package cache and temporary files
dnf clean all && \
rm -rf /tmp/* /var/cache/dnf/* /var/tmp/*


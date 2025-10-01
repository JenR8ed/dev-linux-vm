#!/usr/bin/env bash

set -oue pipefail

# Update system packages
dnf update -y

# Install X11 and development essentials
dnf install -y \
    # X11 support
    xorg-x11-server-utils \
    xorg-x11-xauth \
    xorg-x11-apps \
    \
    # Development tools
    git \
    gh \
    curl \
    wget \
    vim \
    nano \
    tmux \
    \
    # Web development
    nodejs \
    npm \
    python3 \
    python3-pip \
    \
    # Native IDEs and editors
    code \
    gedit \
    neovim \
    \
    # Additional development tools
    docker \
    podman \
    make \
    gcc \
    g++ \
    \
    # Network tools
    openssh-server \
    rsync

# Install VSCodium (open source VS Code)
curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list

# Install GitHub CLI
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
dnf install -y gh

# Install additional web development tools
npm install -g \
    @angular/cli \
    @vue/cli \
    create-react-app \
    typescript \
    eslint \
    prettier

# Python development tools
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

# Configure X11 forwarding helper script
cat > /usr/local/bin/setup-x11 << 'EOF'
#!/bin/bash
# X11 forwarding setup helper
echo "Setting up X11 forwarding..."
export DISPLAY=${DISPLAY:-localhost:10.0}
xauth list
echo "X11 setup complete. Try running: xclock"
EOF
chmod +x /usr/local/bin/setup-x11

# Create development directories
mkdir -p /opt/dev-tools
mkdir -p /home/developer/{projects,scripts,tools}

# Install JetBrains Toolbox (for IntelliJ IDEA, WebStorm, etc.)
wget -O /tmp/jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /opt/dev-tools/
ln -s /opt/dev-tools/jetbrains-toolbox-*/jetbrains-toolbox /usr/local/bin/

# Clean up
dnf clean all
rm -rf /tmp/*
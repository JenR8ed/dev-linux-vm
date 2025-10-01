#!/usr/bin/env bash

set -oue pipefail

# Update system packages
dnf update -y

# Install X11 and development essentials
dnf install -y \
    xorg-x11-xauth \
    xorg-x11-apps \
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
    gedit \
    neovim \
    podman \
    make \
    gcc \
    g++ \
    openssh-server \
    openssh-clients \
    rsync

# Install GitHub CLI
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
dnf install -y gh

# Install VSCodium (open source VS Code) - Fedora/RPM version
curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg
echo '[vscodium]
name=gitlab.com_paulcarroty_vscodium-deb-rpm-repo
baseurl=https://download.vscodium.com/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg' > /etc/yum.repos.d/vscodium.repo
dnf install -y vscodium

# Install web development tools via npm
npm install -g \
    @angular/cli \
    @vue/cli \
    create-react-app \
    typescript \
    eslint \
    prettier \
    http-server \
    live-server

# Install Python development tools
pip3 install \
    flask \
    django \
    fastapi \
    requests \
    virtualenv \
    jupyter

# Configure SSH for X11 forwarding
mkdir -p /etc/ssh/sshd_config.d/
cat > /etc/ssh/sshd_config.d/99-x11-forwarding.conf << EOF
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
EOF

# Create development user with secure setup
useradd -m -G wheel developer
# Generate random password or use SSH keys instead
echo "developer:$(date +%s | sha256sum | base64 | head -c 32)" | chpasswd

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

# Test X11 forwarding
cat > /usr/local/bin/test-x11 << 'EOF'
#!/bin/bash
echo "Testing X11 forwarding..."
echo "DISPLAY: $DISPLAY"
xauth list
echo "Starting xclock test (close to continue)..."
xclock &
XCLOCK_PID=$!
sleep 3
kill $XCLOCK_PID 2>/dev/null
echo "X11 test complete!"
EOF
chmod +x /usr/local/bin/test-x11

# Create development directories
mkdir -p /opt/dev-tools
mkdir -p /home/developer/{projects,tools,scripts}
chown -R developer:developer /home/developer/

# JetBrains Toolbox installation removed for stability

# Clean up
dnf clean all
rm -rf /tmp/*
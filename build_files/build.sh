#!/usr/bin/env bash

set -oue pipefail

# Update system packages
dnf update -y

# Install X11 and development essentials
dnf install -y --skip-unavailable \
    xorg-x11-xauth \
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
dnf install -y --skip-unavailable 'dnf-command(config-manager)'
curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo | tee /etc/yum.repos.d/gh-cli.repo
dnf install -y --skip-unavailable gh

# VSCodium installation removed - package not available in Fedora repositories

# Install web development tools via npm
mkdir -p /root
npm config set prefix /usr/local
npm install -g \
    @angular/cli \
    @vue/cli \
    create-react-app \
    typescript \
    eslint \
    prettier \
    http-server \
    live-server || echo "Some npm packages failed to install, continuing..."

# Install Python development tools
pip3 install \
    flask \
    django \
    fastapi \
    requests \
    virtualenv \
    jupyter || echo "Some Python packages failed to install, continuing..."

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
useradd -m -G wheel developer || true
# Generate random password or use SSH keys instead
mkdir -p /var/spool/mail
echo "developer:$(date +%s | sha256sum | base64 | head -c 32)" | chpasswd 2>/dev/null || echo "Password set failed, using SSH keys only"

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
# Fix broken /usr/local symlink in Universal Blue base image
# /usr/local -> ../var/usrlocal but /var/usrlocal doesn't exist
if [ -L /usr/local ]; then
    # Create the target directory for the symlink
    mkdir -p /var/usrlocal
    # Now we can create subdirectories
    mkdir -p /usr/local/bin
else
    # If it's not a symlink, ensure it's a directory
    [ ! -d /usr/local ] && mkdir -p /usr/local
    mkdir -p /usr/local/bin
fi
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

# Copy systemd service files
mkdir -p /etc/systemd/system
cp /tmp/files/etc/systemd/system/dev-setup.service /etc/systemd/system/ 2>/dev/null || true

# Copy development environment setup script
cp /tmp/files/usr/local/bin/setup-dev-env /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/setup-dev-env 2>/dev/null || true

# Create development directories
# Fix broken /opt symlink in Universal Blue base image
# /opt -> var/opt but /var/opt doesn't exist
if [ -L /opt ]; then
    mkdir -p /var/opt/dev-tools
else
    mkdir -p /opt/dev-tools
fi
mkdir -p /home/developer/{projects,tools,scripts}
chown -R developer:developer /home/developer/

# JetBrains Toolbox installation removed for stability

# Clean up
dnf clean all
rm -rf /tmp/*
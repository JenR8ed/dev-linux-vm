# Base image - using Universal Blue base with development tools
FROM ghcr.io/ublue-os/base-main:latest

# Copy build files first for better layer caching
COPY build_files/build.sh /tmp/build.sh
COPY files/ /tmp/files/

# Run build script and enable services in single layer
RUN chmod +x /tmp/build.sh && \
    /tmp/build.sh && \
    systemctl enable sshd dev-setup && \
    bootc container lint
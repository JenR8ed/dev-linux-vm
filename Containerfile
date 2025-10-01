# Base image - using Universal Blue base with development tools
FROM ghcr.io/ublue-os/base-main:latest

# Copy build files
COPY build.sh /tmp/build.sh
COPY files/ /tmp/files/

# Run build script
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# Enable X11 forwarding by default
RUN systemctl enable sshd

# Final system validation
RUN bootc container lint
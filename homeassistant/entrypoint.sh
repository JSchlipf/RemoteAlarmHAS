#!/bin/sh
# Entrypoint that starts sshd and Home Assistant

# Generate SSH host keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Set root password from environment variable (default: root)
ROOT_PASSWORD=${SSH_ROOT_PASSWORD:-root}
echo "root:${ROOT_PASSWORD}" | chpasswd

# Start SSH daemon in background (without -D to allow backgrounding)
/usr/sbin/sshd &

# Copy initial config files if needed
cp -n /initial-config/*.yaml /initial-config/*.yml /config/ 2>/dev/null || true

# Start Home Assistant
exec python3 -m homeassistant --config /config

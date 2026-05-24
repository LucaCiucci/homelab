#!/bin/sh
set -e

# Restore/generate SSH host keys
if ls /etc/ssh/keys/ssh_host_* > /dev/null 2>&1; then
    cp /etc/ssh/keys/ssh_host_* /etc/ssh/
else
    ssh-keygen -A
    mkdir -p /etc/ssh/keys
    cp /etc/ssh/ssh_host_* /etc/ssh/keys/
fi

# Ensure the git home directory is owned by the git user (volume mount may default to root)
chown git:git /var/lib/git

# Initialize gitolite if not already set up
if [ ! -f /var/lib/git/.gitolite.rc ]; then
    if [ -z "$SSH_KEY" ]; then
        echo "ERROR: SSH_KEY environment variable is required for first-time setup" >&2
        exit 1
    fi
    SSH_KEY_NAME="${SSH_KEY_NAME:-admin}"
    echo "$SSH_KEY" > /var/lib/git/${SSH_KEY_NAME}.pub
    chown git:git /var/lib/git/${SSH_KEY_NAME}.pub
    su -s /bin/sh git -c "gitolite setup -pk /var/lib/git/${SSH_KEY_NAME}.pub"
    rm /var/lib/git/${SSH_KEY_NAME}.pub
fi

# Unlock the git account so sshd allows pubkey auth (Alpine locks it by default)
passwd -u git || true

exec /usr/sbin/sshd -D -e

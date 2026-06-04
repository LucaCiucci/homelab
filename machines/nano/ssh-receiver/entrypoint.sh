#!/bin/sh
set -e

DEPLOY_UID="${DEPLOY_UID:-1001}"

# Create deploy user with fixed UID for consistent permissions
adduser -D -h /home/deploy -s /bin/sh -u "$DEPLOY_UID" deploy
# Set a random password to unlock the account (key auth only, so the password doesn't matter)
echo "deploy:$(openssl rand -base64 32)" | chpasswd

# Set up SSH authorized key
if [ -z "$SSH_PUBLIC_KEY" ]; then
    echo "ERROR: SSH_PUBLIC_KEY environment variable is not set!"
    exit 1
fi

mkdir -p /home/deploy/.ssh
echo "$SSH_PUBLIC_KEY" > /home/deploy/.ssh/authorized_keys
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy

# Ensure target directories exist and are writable by deploy
mkdir -p /srv/e-birb-website /srv/e-birb-website-staging
chown deploy:deploy /srv/e-birb-website /srv/e-birb-website-staging

echo "Starting SSH receiver on port 2222..."
exec /usr/sbin/sshd -D -p 2222 -e

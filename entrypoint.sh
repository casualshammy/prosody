#!/bin/bash
set -e

EXTERNAL_IP=$(wget -qO- https://api.ipify.org/)

echo "Starting Prosody and Coturn..."
echo "User: $USER ($UID)"
echo "External IP: $EXTERNAL_IP"
echo "  - PROSODY_DOMAIN: $PROSODY_DOMAIN"
echo "  - PROSODY_ALLOW_REGISTRATION: $PROSODY_ALLOW_REGISTRATION"
echo "  - PROSODY_ADMIN: $PROSODY_ADMIN"
echo "  - PROSODY_E2E_ENCRYPTION_REQUIRED: $PROSODY_E2E_ENCRYPTION_REQUIRED"
echo "  - PROSODY_E2E_ENCRYPTION_WHITELIST: $PROSODY_E2E_ENCRYPTION_WHITELIST"

RANDOM_SECRET=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)

sed -i "s/^user=.*/user=$RANDOM_SECRET:$RANDOM_SECRET/" /app/turnserver.conf
sed -i "s/^realm=.*/realm=$PROSODY_DOMAIN/" /app/turnserver.conf
sed -i "s/^static-auth-secret=.*/static-auth-secret=$RANDOM_SECRET/" /app/turnserver.conf
sed -i "s/^external-ip=.*/external-ip=$EXTERNAL_IP/" /app/turnserver.conf
sed -i "s/^turn_external_secret=.*/turn_external_secret=\"$RANDOM_SECRET\"/" /etc/prosody/conf.d/01-modules.cfg.lua

/usr/bin/turnserver -c /app/turnserver.conf --daemon --pidfile=/app/turnserver.pid
/usr/bin/prosody -F

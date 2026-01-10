#!/bin/bash
set -e

if [ -n "$PROSODY_EXTERNAL_IP" ]; then
  EXTERNAL_IP="$PROSODY_EXTERNAL_IP"
else
  EXTERNAL_IP=$(wget -qO- https://api.ipify.org/)
fi

echo "Starting Prosody and Coturn..."
echo "User: $USER ($UID)"
echo "External IP: $EXTERNAL_IP"
echo "  - PROSODY_DOMAIN: $PROSODY_DOMAIN"
echo "  - PROSODY_EXTERNAL_IP: $PROSODY_EXTERNAL_IP"
echo "  - PROSODY_ADMIN: $PROSODY_ADMIN"
echo "  - PROSODY_ALLOW_REGISTRATION: $PROSODY_ALLOW_REGISTRATION"
echo "  - PROSODY_E2E_ENCRYPTION_REQUIRED: $PROSODY_E2E_ENCRYPTION_REQUIRED"
echo "  - PROSODY_E2E_ENCRYPTION_WHITELIST: $PROSODY_E2E_ENCRYPTION_WHITELIST"

RANDOM_SECRET=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)

echo "Adjusting configuration..."
sed -i "s/^realm=.*/realm=$PROSODY_DOMAIN/" /app/turnserver.conf
sed -i "s/^static-auth-secret=.*/static-auth-secret=$RANDOM_SECRET/" /app/turnserver.conf
sed -i "s/^external-ip=.*/external-ip=$EXTERNAL_IP/" /app/turnserver.conf
sed -i "s/^turn_external_secret=.*/turn_external_secret=\"$RANDOM_SECRET\"/" /etc/prosody/conf.d/01-modules.cfg.lua
sed -i "s|://[^:]*:|://$PROSODY_DOMAIN:|g" /app/www/.well-known/host-meta

echo "Starting www server..."
nohup npx http-server /app/www --port 443 -a 0.0.0.0 -d false -i false --cors $PROSODY_DOMAIN --log-ip --tls --cert "/app/certs/$PROSODY_DOMAIN/fullchain.pem" --key "/app/certs/$PROSODY_DOMAIN/privkey.pem" &

echo "Starting turnserver..."
/usr/bin/turnserver -c /app/turnserver.conf --daemon --pidfile=/app/turnserver.pid

echo "Starting prosody..."
/usr/bin/prosody -F

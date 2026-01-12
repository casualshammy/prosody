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

# Configure S3 upload if PROSODY_S3_ENABLED is set
if [ -n "$PROSODY_S3_ENABLED" ]; then
  echo "Configuring S3 upload..."
  
  echo "  - S3_REGION: $PROSODY_S3_REGION"
  echo "  - S3_BUCKET: $PROSODY_S3_BUCKET"
  echo "  - S3_FOLDER: $PROSODY_S3_PATH"
  
  # Replace S3 configuration in vhost config
  sed -i "s/Component (domain_http_upload) \"http_file_share\"/Component (domain_http_upload) \"http_upload_s3\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s|http_upload_s3_access_id = \".*\"|http_upload_s3_access_id = \"$PROSODY_S3_ACCESS_ID\"|" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s|http_upload_s3_secret_key = \".*\"|http_upload_s3_secret_key = \"$PROSODY_S3_SECRET_KEY\"|" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s/http_upload_s3_region = \".*\"/http_upload_s3_region = \"$PROSODY_S3_REGION\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s/http_upload_s3_bucket = \".*\"/http_upload_s3_bucket = \"$PROSODY_S3_BUCKET\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s|http_upload_s3_path  = \".*\"|http_upload_s3_path  = \"$PROSODY_S3_PATH\"|" /etc/prosody/conf.d/05-vhost.cfg.lua
else
  echo "S3 upload not configured, using local http_file_share..."
  # Restore original configuration
  sed -i "s/Component (domain_http_upload) \"http_upload_s3\"/Component (domain_http_upload) \"http_file_share\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s/http_upload_s3_access_id = \".*\"/http_upload_s3_access_id = \"S3_SECRET_ID\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s/http_upload_s3_secret_key = \".*\"/http_upload_s3_secret_key = \"S3_SECRET_KEY\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s/http_upload_s3_region = \".*\"/http_upload_s3_region = \"S3_REGION\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s/http_upload_s3_bucket = \".*\"/http_upload_s3_bucket = \"S3_BUCKET\"/" /etc/prosody/conf.d/05-vhost.cfg.lua
  sed -i "s|http_upload_s3_path  = \".*\"|http_upload_s3_path  = \"S3_PATH\"|" /etc/prosody/conf.d/05-vhost.cfg.lua
fi

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

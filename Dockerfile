# ENV
#  - PROSODY_ADMIN
#  - PROSODY_ALLOW_REGISTRATION
#  - PROSODY_DOMAIN
#  - PROSODY_E2E_ENCRYPTION_REQUIRED
#  - PROSODY_E2E_ENCRYPTION_WHITELIST
#  - PROSODY_EXTERNAL_IP

FROM node:24-bookworm-slim

# HTTPS FOR BOSH / WEBSOCKET ADVERTISEMENT
EXPOSE 443/tcp

# TURN SERVER PORTS
EXPOSE 3478/tcp 
EXPOSE 3478/udp

# File transfer proxy
EXPOSE 5000/tcp

# Client connections
EXPOSE 5222/tcp

# Client connections - direct TLS
EXPOSE 5223/tcp

# Server-to-server connections
EXPOSE 5269/tcp

# HTTPS
EXPOSE 5281/tcp

WORKDIR /app

# Install packages, download modules, create user, and configure in single layer
RUN apt update -y && \ 
  apt install wget -y && \
  wget https://prosody.im/downloads/repos/bookworm/prosody.sources -O /etc/apt/sources.list.d/prosody.sources && \
  apt update -y && \
  apt install prosody coturn lua-dbi-common lua-dbi-sqlite3 -y && \
  apt remove liblua5.1-0-dev liblua5.1-0 lua5.1 -y && \ 
  apt purge -y --auto-remove && \
  rm -rf /var/lib/apt/lists/* && \
  # Create folder structure
  mkdir -p /app/certs /app/data /app/modules && \
  # Download and unpack Prosody modules
  wget https://hg.prosody.im/prosody-modules/archive/tip.tar.gz && \
  tar -xzf tip.tar.gz -C /app/modules --strip-components=1 && \
  rm tip.tar.gz && \
  rm -rf /app/modules/mod_cloud_notify && \
  # Create prosody_app user
  useradd --uid 9999 prosody_app && \
  groupmod -g 9999 prosody_app && \
  mkdir -p /home/prosody_app && \
  chown -R prosody_app:prosody_app /home/prosody_app && \
  # Configure coturn
  { \
    echo 'min-port=50000'; \
    echo 'max-port=50100'; \
    echo 'no-multicast-peers'; \
    echo 'no-cli'; \
    echo 'no-tlsv1'; \
    echo 'no-tlsv1_1'; \
    echo 'log-file=stdout'; \
    echo 'realm=REALM'; \
    echo 'use-auth-secret'; \
    echo 'static-auth-secret=AUTH_SECRET'; \
    echo 'external-ip=0.0.0.0'; \
  } >> /etc/turnserver.conf && \
  cp /etc/turnserver.conf /app/turnserver.conf && \
  rm -rf /etc/prosody/conf.d/localhost.cfg.lua

# Copy configuration files (separate layer for better caching)
COPY --chown=prosody_app:prosody_app ./conf/prosody.cfg.lua /etc/prosody/prosody.cfg.lua
COPY --chown=prosody_app:prosody_app ./conf/conf.d /etc/prosody/conf.d
COPY --chown=prosody_app:prosody_app --chmod=755 ./entrypoint.sh /app/entrypoint.sh
COPY --chown=prosody_app:prosody_app ./www /app/www
  
USER prosody_app

ENTRYPOINT ["/app/entrypoint.sh"]

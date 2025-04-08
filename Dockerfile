# ENV
#  - PROSODY_ADMIN
#  - PROSODY_ALLOW_REGISTRATION
#  - PROSODY_DOMAIN
#  - PROSODY_E2E_ENCRYPTION_REQUIRED
#  - PROSODY_E2E_ENCRYPTION_WHITELIST
#  - PROSODY_EXTERNAL_IP

FROM debian:bookworm-slim

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
RUN apt update -y && apt install wget prosody coturn lua-dbi-common lua-dbi-sqlite3 -y && rm -rf /var/lib/apt/lists/*

# Creating folder structure
RUN mkdir /app/certs && mkdir /app/data && mkdir /app/modules

# Download and unpack Prosody modules
RUN wget https://hg.prosody.im/prosody-modules/archive/tip.tar.gz && tar -xzf tip.tar.gz -C "/app/modules" --strip-components=1 && rm tip.tar.gz

COPY ./conf/prosody.cfg.lua /etc/prosody/prosody.cfg.lua
COPY ./conf/conf.d /etc/prosody/conf.d
COPY ./entrypoint.sh /app/entrypoint.sh

RUN useradd --uid 9999 prosody_app && groupmod -g 9999 prosody_app

RUN \
  echo 'min-port=50000' >> /etc/turnserver.conf && \
  echo 'max-port=50100' >> /etc/turnserver.conf && \
  echo 'no-multicast-peers' >> /etc/turnserver.conf && \
  echo 'no-cli' >> /etc/turnserver.conf && \
  echo 'no-tlsv1' >> /etc/turnserver.conf && \
  echo 'no-tlsv1_1' >> /etc/turnserver.conf && \
  echo 'log-file=stdout' >> /etc/turnserver.conf && \
  echo 'realm=REALM' >> /etc/turnserver.conf && \
  echo 'use-auth-secret' >> /etc/turnserver.conf && \
  echo 'static-auth-secret=AUTH_SECRET' >> /etc/turnserver.conf && \
  echo 'external-ip=0.0.0.0' >> /etc/turnserver.conf && \
  cp /etc/turnserver.conf /app/turnserver.conf && \
  rm -rf /etc/prosody/conf.d/localhost.cfg.lua && \
  chmod +x /app/entrypoint.sh && \
  chown -R prosody_app:prosody_app /app && \
  chown -R prosody_app:prosody_app /etc/prosody
  
USER prosody_app

ENTRYPOINT ["/app/entrypoint.sh"]

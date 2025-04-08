# Prosody Docker Image with STUN/TURN
This Docker image is designed for those who want to run their own XMPP server without dealing with configuration files.

## Features
- Based on the well-established XMPP server [Prosody](https://prosody.im/).
- Configured to achieve a 100% score on the [XMPP Compliance Tester](https://compliance.conversations.im/).
- Audio/video call support: the image includes a configured STUN/TURN server [coturn](https://github.com/coturn/coturn).
- Unencrypted connections between clients and the server are prohibited. E2E encryption is [optionally] mandatory.
- Minimal setup: only the absolute minimum configuration is required.

## Running the Server
### Preparation
You will need:
- A computer with an external IP address capable of running Docker images for linux/amd64.
- DNS setup. Suppose you want your XMPP server to be hosted on the domain `example.com`; then the following domains must point (A or AAAA record) to the external IP address:
   - `example.com`
   - `upload.example.com`
   - `muc.example.com`
   - `proxy.example.com`
   - `pubsub.example.com`

Of course, you can use a subdomain, such as `xmpp.example.com`.

### Deployment
1. Create a folder that a user with UID `9999` can read and write to (the user does not need to exist; simply run `chown -R 9999:9999 <YOUR-FOLDER>`). This folder is needed to store user data independently of the Docker container's state. We will assume this folder is `/home/prosody`. Inside `/home/prosody`, create two subfolders: `certs` and `data`.
2. In the `/home/prosody/certs` folder, store the certificates for the main domain and the `upload.` subdomain. Suppose you want your XMPP server to be hosted on the domain `example.com`. Then the file and folder structure should be as follows (mirroring the structure of Let's Encrypt):
   - certs
      - example.com
         - fullchain.pem
         - privkey.pem
      - upload.example.com
         - fullchain.pem
         - privkey.pem
3. Create a `docker-compose.yml` file with the following content (don't forget to replace `example.com` with your domain and `/home/prosody` with your folder where the Prosody database is stored):
```yml
services:
  server:
    image: oixa/prosody:latest
    restart: always
    ports:
      - "3478:3478/tcp"
      - "3478:3478/udp"
      - "5000:5000/tcp"
      - "5222:5222/tcp"
      - "5223:5223/tcp"
      - "5269:5269/tcp"
      - "5281:5281/tcp"
      - "50000-50100:50000-50100/udp"
    environment:
      PROSODY_ADMIN: admin@example.com
      PROSODY_ALLOW_REGISTRATION: false
      PROSODY_DOMAIN: example.com
      PROSODY_E2E_ENCRYPTION_REQUIRED: true
      PROSODY_E2E_ENCRYPTION_WHITELIST: noreply@example.com
    volumes:
      - /home/prosody/certs:/app/certs:ro
      - /home/prosody/data:/app/data
```
4. Start the server with the command `docker compose up -d`.
5. To register a user (if you have not allowed registration via XMPP clients), use the following command: `docker exec -it prosody-server-1 prosodyctl register <LOGIN> <DOMAIN> <PASSWORD>`. Don't forget to replace the placeholders with your data!
6. If you cannot log in, restart the server and check the logs in the console: `docker compose down && docker compose up`.

### Environment Variables
- `PROSODY_DOMAIN`: (MANDATORY) The domain where your server will operate.
- `PROSODY_EXTERNAL_IP`: External IP. Useful if your computer has more than 1 external IP address.
- `PROSODY_ADMIN`: JID of the server administrator.
- `PROSODY_ALLOW_REGISTRATION`: Whether to allow free registration on the server.
- `PROSODY_E2E_ENCRYPTION_REQUIRED`: Whether E2E encryption is mandatory.
- `PROSODY_E2E_ENCRYPTION_WHITELIST`: A comma-separated list of JIDs for which E2E encryption is not mandatory.
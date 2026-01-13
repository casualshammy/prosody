# Prosody Docker Image with STUN/TURN
This Docker image is designed for those who want to run their own XMPP server without dealing with complex configuration files.

[![Docker Pulls](https://img.shields.io/docker/pulls/oixa/prosody?style=for-the-badge&label=oixa%2Fprosody&link=https%3A%2F%2Fhub.docker.com%2Fr%2Foixa%2Fprosody)](https://hub.docker.com/r/oixa/prosody)

## Features
- Based on the well-established XMPP server [Prosody](https://prosody.im/).
- Configured to achieve a 100% score on the [XMPP Compliance Tester](https://compliance.conversations.im/).
- Audio/video call support: the image includes a pre-configured STUN/TURN server [coturn](https://github.com/coturn/coturn).
- Option to use [AWS S3](https://aws.amazon.com/s3/) as file storage.
- Unencrypted connections between clients and the server are prohibited. End-to-end (E2E) encryption is optionally mandatory.
- Minimal setup: only the absolute minimum configuration is required.

## Running the Server
### Preparation
You will need:
- A computer with an external IP address capable of running Docker images for `linux/amd64` or `linux/arm64` architecture.
- DNS setup. Suppose you want your XMPP server to be hosted on the domain `example.com`. The following domains must point (A or AAAA record) to the external IP address:
   - `example.com`
   - `upload.example.com`
   - `muc.example.com`
   - `proxy.example.com`
   - `pubsub.example.com`

Alternatively, you can use a subdomain, such as `xmpp.example.com`.

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
3. Create a `docker-compose.yml` file with the following content (replace `example.com` with your domain and `/home/prosody` with the path to your data folder):
   ```yml
   services:
     server:
       image: oixa/prosody:latest
       restart: always
       ports:
         - "443:443/tcp"
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
   **Note:** If you do not plan to use web-based XMPP clients (such as [Converse.js](https://conversejs.org/)), you can remove the port `443:443/tcp` mapping from the configuration.  
4. Start the server with the command `docker compose up -d`.
5. If you cannot log in, restart the server and check the logs in the console: `docker compose down && docker compose up`.

### Using S3 for File Storage

By default, Prosody stores uploaded files locally on disk. However, you can configure it to use AWS S3 for file storage.

#### Benefits of Using S3
- **Scalability**: No need to worry about disk space on your server.
- **Reliability**: Data is stored with redundancy in the cloud.
- **Availability**: Files are accessible directly from the S3 bucket.
- **Separation of concerns**: File storage is separated from the Prosody server.

#### Configuring S3 Storage

To use S3, add [environment variables](#environment-variables) starting from `PROSODY_S3_` to your `docker-compose.yml`. Setting up the S3 bucket is beyond the scope of this README; please refer to AWS S3 documentation.

**Note:** Your bucket policy must allow public read access.

#### Switching Between Local and S3 Storage

To **switch back to local storage**, simply remove the `PROSODY_S3_ENABLED` variable from the configuration or set it to an empty value.

**Note:** When switching, existing files are not migrated automatically. Files uploaded to S3 will remain in S3, and new files will be stored locally (or vice versa).

## Useful commands
1. To register a user (if you have not allowed registration via XMPP clients), use the following command: `docker exec -it prosody-server-1 prosodyctl register <LOGIN> <DOMAIN> <PASSWORD>`. Replace the placeholders with your data.
2. To display live logs: `docker logs -ft prosody-server-1`
3. To print the TURN server password, use the following command: `docker exec -it prosody-server-1 cat turnserver.conf | grep static-auth-secret=`

## Environment Variables
- `PROSODY_DOMAIN`: (MANDATORY) The domain where your server will operate.
- `PROSODY_EXTERNAL_IP`: External IP address. Useful if your computer has more than one external IP address.
- `PROSODY_ADMIN`: JID of the server administrator.
- `PROSODY_ALLOW_REGISTRATION`: Whether to allow free registration on the server.
- `PROSODY_E2E_ENCRYPTION_REQUIRED`: Whether E2E encryption is mandatory.
- `PROSODY_E2E_ENCRYPTION_WHITELIST`: A comma-separated list of JIDs for which E2E encryption is not mandatory.
- `PROSODY_S3_ENABLED`: Set any non-empty value to use AWS S3 as file storage.
- `PROSODY_S3_ACCESS_ID`: Access Key ID for S3 access.
- `PROSODY_S3_SECRET_KEY`: Secret Access Key for S3 access.
- `PROSODY_S3_REGION`: S3 region (e.g., `us-east-1`, `eu-west-1`).
- `PROSODY_S3_BUCKET`: S3 bucket name.
- `PROSODY_S3_PATH`: Path inside the bucket (e.g., `uploads/`).

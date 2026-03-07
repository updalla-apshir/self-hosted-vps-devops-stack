# VPS Setup Guide

A comprehensive step-by-step guide to setting up your production VPS from scratch.

## Prerequisites

Before starting, ensure you have:

- A Hetzner Cloud account
- A domain name pointed to your VPS (optional but recommended)
- SSH client (Terminal on macOS/Linux, PuTTY on Windows)
- Basic knowledge of Linux command line

## Step 1: Create Hetzner VPS

### 1.1 Create a New Project

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud)
2. Create a new project named "Production"
3. Note down your project credentials

### 1.2 Provision a Server

1. Click "Add Server" in your project
2. Choose the following settings:
   - **Location**: Frankfurt (or your closest datacenter)
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX31 (4 vCPU, 8GB RAM, 160GB SSD) - or adjust as needed
   - **Networking**: Enable IPv4 and IPv6
   - **SSH Key**: Add your SSH public key
   - **Name**: production-vps

3. Click "Create & Buy Now"

### 1.3 Note Server Details

After creation, note these important details:

- Public IPv4 address
- Public IPv6 address
- Server hostname

## Step 2: Initial Server Connection

### 2.1 Connect via SSH

```bash
ssh root@your_server_ip
```

### 2.2 Update System

```bash
apt update && apt upgrade -y
```

### 2.3 Set Hostname

```bash
hostnamectl set-hostname production-vps
echo "127.0.1.1 production-vps" >> /etc/hosts
```

## Step 3: Server Security Hardening

### 3.1 Create Non-Root User

```bash
# Create new user
adduser deployer

# Add to sudo group
usermod -aG sudo deployer

# Copy SSH key to new user
rsync --archive --chown=deployer:deployer ~/.ssh /home/deployer/
```

### 3.2 Configure SSH

```bash
# Edit SSH configuration
nano /etc/ssh/sshd_config
```

Make these changes:

```
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
```

```bash
# Restart SSH
systemctl restart sshd
```

### 3.3 Setup Firewall

```bash
# Install UFW
apt install ufw -y

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw enable
```

### 3.4 Automatic Security Updates

```bash
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades
```

## Step 4: Install Docker

### 4.1 Install Dependencies

```bash
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

### 4.2 Add Docker GPG Key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### 4.3 Add Docker Repository

```bash
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4.4 Install Docker

```bash
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### 4.5 Configure Docker

```bash
# Enable Docker on boot
systemctl enable docker

# Add user to docker group
usermod -aG docker deployer

# Configure Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
```

## Step 5: Install Dokploy

### 5.1 Run Dokploy Installer

```bash
# Switch to deployer user
su - deployer

# Install Dokploy
bash -c "$(curl -fsSL https://get.dokploy.com)"
```

### 5.2 Configure Domain

After installation, access Dokploy at:

```
https://dokploy.yourdomain.com
```

Follow the web UI setup:

1. Create admin account
2. Configure domain
3. Set up SSL

### 5.3 Install Traefik

Dokploy automatically installs Traefik as the reverse proxy. Verify it's running:

```bash
docker ps | grep traefik
```

## Step 6: Configure DNS

### 6.1 Create DNS Records

In your domain registrar or cloud DNS:

| Type | Name    | Value            |
| ---- | ------- | ---------------- |
| A    | dokploy | your_server_ip   |
| A    | umami   | your_server_ip   |
| A    | uptime  | your_server_ip   |
| A    | yourapp | your_server_ip   |
| AAAA | dokploy | your_server_ipv6 |
| AAAA | umami   | your_server_ipv6 |

### 6.2 Verify DNS Propagation

```bash
dig dokploy.yourdomain.com
nslookup dokploy.yourdomain.com
```

## Step 7: Install Monitoring Tools

### 7.1 Install Uptime Kuma

```bash
# Using Docker Compose
mkdir -p /opt/uptimer-kuma
cd /opt/uptimer-kuma

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    volumes:
      - uptime-kuma:/app/data
    ports:
      - "3002:3001"

volumes:
  uptime-kuma:
    name: uptime-kuma
EOF

docker compose up -d
```

### 7.2 Install Beszel

```bash
mkdir -p /opt/beszel
cd /opt/beszel

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  beszel:
    image: henrywhittaker/beszel:latest
    container_name: beszel
    restart: unless-stopped
    ports:
      - "3003:3000"
    volumes:
      - ./beszel-data:/app/data
      - /var/run/docker.sock:/var/run/docker.sock
EOF

docker compose up -d
```

### 7.3 Install Umami

```bash
mkdir -p /opt/umami
cd /opt/umami

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  umami:
    image: ghcr.io/umami-software/umami:postgresql-latest
    container_name: umami
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      DATABASE_URL: postgresql://umami:umami@db:5432/umami
      DATABASE_TYPE: postgresql
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    container_name: umami-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: umami
      POSTGRES_USER: umami
      POSTGRES_PASSWORD: umami
    volumes:
      - umami-db:/var/lib/postgresql/data

volumes:
  umami-db:
    name: umami-db
EOF

docker compose up -d
```

## Step 8: Configure Traefik Middleware

### 8.1 Security Headers

Create `middleware.yaml`:

```yaml
http:
  middlewares:
    security-headers:
      headers:
        frameDeny: true
        contentTypeNosniff: true
        browserXssFilter: true
        sslRedirect: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000

    compress:
      compress: {}

    rate-limit:
      rateLimit:
        average: 100
        burst: 50
```

### 8.2 Apply Middleware

```bash
docker config create traefik-middleware /path/to/middleware.yaml
```

## Step 9: Verify Everything Works

### 9.1 Check All Containers

```bash
docker ps
```

### 9.2 Check Logs

```bash
# Traefik logs
docker logs traefik

# Dokploy logs
docker logs dokploy
```

### 9.3 Test SSL Certificates

```bash
# Check Traefik certificates
docker exec traefik ls -la /letsencrypt/acme.json
```

## Step 10: Setup Backups

Follow the [Backup Script](../scripts/backup-script.sh) to configure automated backups.

## Next Steps

- Read the [Deployment Guide](./deployment.md) to learn about deploying applications
- Configure monitoring alerts in [Monitoring Guide](./monitoring.md)
- Review [Architecture Overview](./architecture.md) for system details

## Troubleshooting

### Common Issues

**Can't connect to server:**

- Check firewall: `ufw status`
- Check SSH: `systemctl status sshd`

**Docker not working:**

- Check Docker status: `systemctl status docker`
- Check logs: `journalctl -u docker -f`

**SSL certificate issues:**

- Check Traefik logs: `docker logs traefik`
- Verify DNS is pointing correctly

## Support

If you encounter issues:

1. Check logs for each service
2. Review Docker container status
3. Verify network/firewall settings
4. Consult the [GitHub Issues](https://github.com/yourusername/production-vps-setup/issues)

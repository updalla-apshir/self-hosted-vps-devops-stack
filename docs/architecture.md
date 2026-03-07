# System Architecture

This document provides an in-depth explanation of the production VPS architecture and how all components interact.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Traefik (Reverse Proxy)                      │
│              Ports: 80, 443, Dashboard: 8080                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
┌───────────────┐ ┌───────────┐ ┌──────────────┐
│   Dokploy     │ │  Umami    │ │ Uptime Kuma  │
│  (Port 3000)  │ │ (Port 3001)│ │ (Port 3002)  │
└───────────────┘ └───────────┘ └──────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Docker Daemon                              │
│                   Container Runtime                             │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Hetzner VPS                                  │
│               Ubuntu 22.04 LTS                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Traefik Reverse Proxy

Traefik acts as the entry point for all HTTP/HTTPS traffic:

- **Port 80**: HTTP traffic (redirects to HTTPS)
- **Port 443**: HTTPS traffic with automatic TLS
- **Dashboard**: Internal access on port 8080

**Key Features:**

- Automatic service discovery from Docker labels
- Let's Encrypt integration for free SSL certificates
- Middleware for rate limiting, authentication, and redirects
- WebSocket support

### 2. Dokploy Deployment Platform

Dokploy is a self-hosted PaaS built on Coolify:

- **Web Interface**: Accessible via Traefik
- **Git Integration**: Connects to GitHub, GitLab, Bitbucket
- **Database Support**: MySQL, PostgreSQL, MongoDB, Redis
- **Scheduler**: Cron job support
- **SSL Management**: Automatic certificate provisioning

### 3. Monitoring Stack

#### Uptime Kuma

- Self-hosted uptime monitoring
- Supports HTTP, TCP, Ping, and DNS checks
- Status pages with custom branding
- Alert notifications via Telegram, Discord, Email

#### Beszel

- Lightweight resource monitoring
- Docker container metrics
- Historical data storage
- Multi-server support

### 4. Umami Analytics

- Privacy-focused web analytics
- No cookie consent required (GDPR compliant)
- Real-time visitor tracking
- Export data to CSV/Excel

## Network Architecture

### Port Usage

| Port | Service           | Description           |
| ---- | ----------------- | --------------------- |
| 22   | SSH               | Server administration |
| 80   | HTTP              | Web traffic (Traefik) |
| 443  | HTTPS             | Secure web traffic    |
| 8080 | Traefik Dashboard | Internal only         |
| 3000 | Dokploy           | Internal only         |
| 3001 | Umami             | Exposed via Traefik   |
| 3002 | Uptime Kuma       | Exposed via Traefik   |
| 3003 | Beszel            | Exposed via Traefik   |

### Firewall Rules

```bash
# Allow SSH
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw enable
```

## Data Flow

1. **User Request**: Browser sends HTTPS request to domain
2. **DNS Resolution**: Domain points to Hetzner VPS IP
3. **Traefik Routing**: Request hits Traefik, routes based on hostname
4. **Backend Processing**: Application container processes request
5. **Response**: Container responds through Traefik to user

## Storage Structure

```
/
├── /var/lib/docker          # Docker container data
├── /opt/dokploy            # Dokploy application data
├── /opt/umami              # Umami analytics data
├── /opt/backup             # Backup storage
└── /etc/traefik            # Traefik configuration
```

## Security Considerations

### Network Security

- All services behind Traefik reverse proxy
- No direct external access to application ports
- UFW firewall enabled with minimal open ports

### TLS/SSL

- Automatic certificate generation via Let's Encrypt
- HTTP to HTTPS redirect enforced
- Modern TLS protocols only (TLS 1.2+)

### Container Isolation

- Non-root users in containers
- Resource limits configured
- Network segmentation between services

## Scalability

### Vertical Scaling

- Upgrade Hetzner VPS plan for more resources
- Add swap space if needed

### Horizontal Scaling

- Deploy additional VPS instances
- Use load balancer for traffic distribution
- Shared storage solutions for state

## Backup Strategy

- Daily automated backups of:
  - Docker volumes
  - Database dumps
  - Configuration files
- Off-site backup storage
- Weekly backup rotation

## Monitoring & Alerting

### Metrics Collected

- CPU usage and load average
- Memory utilization
- Disk usage and I/O
- Network traffic
- Container health status
- Application-specific metrics

### Alert Channels

- Email notifications
- Discord/Telegram webhooks
- SMS (optional)

## Related Documentation

- [Setup Guide](./setup-guide.md) - Initial VPS configuration
- [Deployment Guide](./deployment.md) - Deploying applications
- [Monitoring Guide](./monitoring.md) - Monitoring setup details

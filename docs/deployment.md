# Deployment Guide

Learn how to deploy applications using Dokploy on your production VPS.

## Overview

Dokploy is a powerful self-hosted PaaS that simplifies application deployment. It supports multiple programming languages, databases, and provides features like automatic SSL, Docker support, and CI/CD pipelines.

## Supported Application Types

Dokploy supports deploying:

- **Static Sites**: HTML, React, Vue, Next.js, Nuxt.js
- **Node.js**: Express, NestJS, Fastify
- **Python**: Django, Flask, FastAPI
- **PHP**: Laravel, WordPress, Symfony
- **Go**: Gin, Echo, Fiber
- **Ruby**: Rails, Sinatra
- **Docker**: Custom Dockerfiles and docker-compose

## Prerequisites

Before deploying, ensure:

1. Dokploy is installed and running
2. Your domain DNS is configured
3. You have your application code in a Git repository

## Deploying Your First Application

### Step 1: Create a New Project

1. Navigate to your Dokploy dashboard
2. Click "New Project"
3. Enter project details:
   - **Name**: my-app
   - **Description**: My first application
   - **Organization**: Default

### Step 2: Add Application

1. In your project, click "New Application"
2. Select your Git provider (GitHub, GitLab, Bitbucket)
3. Authorize Dokploy to access your repositories
4. Select the repository to deploy

### Step 3: Configure Build Settings

Configure how your application builds:

#### For Node.js Applications

```
Build Pack: NodeJS
Build Command: npm run build
Run Command: npm start
Port: 3000
```

#### For Python Applications

```
Build Pack: Python
Build Command: pip install -r requirements.txt
Run Command: gunicorn app:app
Port: 8000
```

#### For Static Sites

```
Build Pack: Static
Build Command: npm run build
Output Directory: dist
Port: 3000
```

#### For Docker Applications

```
Build Pack: Dockerfile
Dockerfile Location: Dockerfile
Context: ./
```

### Step 4: Configure Deployment

Set up deployment settings:

```yaml
# Environment variables (add as needed)
NODE_ENV: production
DATABASE_URL: postgres://user:pass@db:5432/mydb
API_KEY: your-api-key
```

### Step 5: Configure Domain

1. Click "Domains" tab
2. Add your domain: `app.yourdomain.com`
3. Enable HTTPS (automatic via Let's Encrypt)
4. Configure SSL settings

### Step 6: Deploy

Click "Deploy" to start your first deployment. You can watch the build logs in real-time.

## Deployment Workflow

### Automatic Deployments

Configure automatic deployments on push:

1. Go to your application settings
2. Enable "Auto Deploy"
3. Select branch to deploy from (usually `main` or `master`)

### Manual Deployments

To deploy manually:

1. Click "Deploy" button in dashboard
2. Select the commit to deploy
3. Wait for build and deployment to complete

### Rollback

To rollback to a previous version:

1. Go to "Deployments" tab
2. Find the previous deployment
3. Click "Redeploy" on that version

## Database Setup

Dokploy supports multiple databases:

### PostgreSQL

```bash
# Create database through Dokploy UI
# Connection string format:
postgresql://username:password@hostname:port/database
```

### MySQL/MariaDB

```bash
# Connection string format:
mysql://username:password@hostname:port/database
```

### MongoDB

```bash
# Connection string format:
mongodb://username:password@hostname:port/database
```

### Redis

```bash
# Connection string format:
redis://username:password@hostname:port/database
```

## Environment Variables

### Adding Environment Variables

1. Go to your application
2. Navigate to "Environment" tab
3. Click "Add Variable"
4. Enter key and value
5. Save and redeploy

### Using Secrets

For sensitive values:

1. Mark variable as "Secret"
2. The value will be hidden in logs
3. Available in your application as environment variable

## Health Checks

Configure health checks to verify your application is running:

```yaml
# HTTP Health Check
Health Check:
  Protocol: http
  Path: /health
  Port: 3000
  Interval: 30s
  Timeout: 10s
  Restart: always
```

## Cron Jobs

Schedule recurring tasks:

1. Go to "Schedules" tab
2. Click "New Schedule"
3. Configure cron expression
4. Set the command to run

Example cron schedules:

```
# Every hour
0 * * * *

# Every day at midnight
0 0 * * *

# Every Monday at 6am
0 6 * * 1
```

## Advanced Configuration

### Persistent Storage

Add persistent volumes for data that needs to survive deployments:

1. Go to "Storage" tab
2. Click "Add Storage"
3. Configure mount path in container

### Resource Limits

Set resource constraints:

```yaml
Resources:
  Memory Limit: 512MB
  CPU Limit: 0.5
  Restart Policy: always
```

### Pre/Post Deployment Scripts

Execute scripts before or after deployment:

```yaml
Pre-Deploy:
  - echo "Starting deployment..."
  - npm run migrate

Post-Deploy:
  - echo "Deployment complete!"
  - npm run seed
```

## Docker Deployment

### Using Dockerfile

Create a `Dockerfile` in your project root:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

### Using docker-compose

Create `docker-compose.yml`:

```yaml
version: "3.8"

services:
  app:
    build: .
    restart: always
    environment:
      - NODE_ENV=production
    volumes:
      - app-data:/app/data

  db:
    image: postgres:15
    restart: always
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  app-data:
  db-data:
```

## Troubleshooting

### Build Failures

**Common causes:**

- Incorrect build command
- Missing dependencies in package.json
- Incorrect Node/Python version

**Solutions:**

1. Check build logs for errors
2. Verify build pack settings
3. Ensure all dependencies are in requirements.txt or package.json

### Application Won't Start

**Check:**

- Port configuration matches your application
- Environment variables are set correctly
- Database connections are valid

### SSL Certificate Issues

**Solutions:**

1. Verify DNS is pointing to server
2. Check domain is reachable on ports 80/443
3. Review Traefik logs

## Best Practices

### Development Workflow

1. Use feature branches for development
2. Deploy staging environments for testing
3. Use Pull Request previews when possible

### Production Deployment

1. Always use environment variables for secrets
2. Set up health checks for all applications
3. Configure proper resource limits
4. Enable auto-backups for databases
5. Use separate environments (staging/production)

### Monitoring

- Set up Uptime Kuma checks for all endpoints
- Configure alerting for deployment failures
- Monitor resource usage with Beszel

## Next Steps

- Configure [Monitoring](./monitoring.md) for your applications
- Review [Architecture](./architecture.md) for system details
- Set up [Backups](../scripts/backup-script.sh) for critical data

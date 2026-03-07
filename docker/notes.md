# Docker Configuration Notes

This folder contains Docker configurations, examples, and best practices for the production VPS setup.

## Docker Compose Examples

### Basic Node.js Application

```yaml
version: "3.8"

services:
  app:
    build: .
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

### Application with Database

```yaml
version: "3.8"

services:
  app:
    image: your-app:latest
    restart: unless-stopped
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      - REDIS_URL=redis://redis:6379
    volumes:
      - app-data:/app/data

  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - db-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis-data:/data

volumes:
  app-data:
  db-data:
  redis-data:
```

## Docker Best Practices

### Security

1. **Never run containers as root**

   ```dockerfile
   # Add user in Dockerfile
   RUN addgroup -g 1001 appgroup && \
       adduser -u 1001 -G appgroup -s /bin/sh -D appuser

   USER appuser
   ```

2. **Use specific image tags**

   ```yaml
   # Bad
   image: node:latest

   # Good
   image: node:18-alpine
   ```

3. **Scan images for vulnerabilities**

   ```bash
   docker scout cves your-image:latest
   ```

4. **Limit container capabilities**
   ```yaml
   security_opt:
     - no-new-privileges:true
   cap_drop:
     - ALL
   ```

### Performance

1. **Use multi-stage builds**

   ```dockerfile
   # Build stage
   FROM node:18 AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build

   # Production stage
   FROM node:18-alpine
   WORKDIR /app
   COPY --from=builder /app/dist ./dist
   COPY --from=builder /app/node_modules ./node_modules
   USER node
   CMD ["node", "dist/index.js"]
   ```

2. **Set resource limits**

   ```yaml
   deploy:
     resources:
       limits:
         cpus: "0.5"
         memory: 512M
       reservations:
         cpus: "0.25"
         memory: 256M
   ```

3. **Use health checks**
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
     interval: 30s
     timeout: 10s
     retries: 3
     start_period: 40s
   ```

## Common Docker Commands

### Container Management

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# View container logs
docker logs -f container_name

# Execute command in container
docker exec -it container_name bash

# Stop/Start container
docker stop container_name
docker start container_name

# Remove container
docker rm container_name
```

### Image Management

```bash
# List images
docker images

# Remove unused images
docker image prune -a

# Build image
docker build -t myapp:latest .

# Tag image
docker tag myapp:latest registry.com/myapp:latest
```

### Volume Management

```bash
# List volumes
docker volume ls

# Create volume
docker volume create mydata

# Inspect volume
docker volume inspect mydata
```

## Traefik Labels

Example Docker Compose with Traefik labels:

```yaml
version: "3.8"

services:
  app:
    image: your-app:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.yourdomain.com`)"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"
      - "traefik.http.services.app.loadbalancer.server.port=3000"
```

### Common Traefik Middleware

```yaml
labels:
  # Security headers
  - "traefik.http.middlewares.security.headers.frameDeny=true"
  - "traefik.http.middlewares.security.headers.contentTypeNosniff=true"
  - "traefik.http.middlewares.security.headers.browserXssFilter=true"

  # Rate limiting
  - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
  - "traefik.http.middlewares.ratelimit.ratelimit.burst=50"

  # Redirect
  - "traefik.http.middlewares.redirect.redirectScheme.scheme=https"
  - "traefik.http.middlewares.redirect.redirectScheme.permanent=true"
```

## Docker Networking

### Custom Network

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

### Connecting to Host Network

```yaml
network_mode: "host"
```

## Logging Configuration

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

Or using Fluentd:

```yaml
logging:
  driver: "fluentd"
  options:
    fluentd-address: localhost:24224
    tag: docker.{{.Name}}
```

## Environment Variables

### Using .env file

```bash
# .env file
DATABASE_URL=postgresql://user:pass@localhost:5432/db
API_KEY=your-secret-key
```

```yaml
# docker-compose.yml
services:
  app:
    env_file:
      - .env
    environment:
      - NODE_ENV=production
```

## Cron Jobs in Docker

```yaml
version: "3.8"

services:
  cron:
    image: your-app:latest
    command: cron -f
    volumes:
      - ./cronjob.sh:/etc/cron.daily/cronjob
```

## Backup Considerations

1. **Back up volumes regularly**

   ```bash
   docker run --rm -v volume-name:/data -v $(pwd):/backup alpine \
     tar czf /backup/backup.tar.gz -C /data .
   ```

2. **Use named volumes**

   ```yaml
   volumes:
     - mydata:/var/lib/data
   ```

3. **Don't store persistent data in containers**
   - Use volumes for data
   - Use bind mounts for configuration

## Useful Tools

- **Docker Scout**: Security scanning
- **Portainer**: GUI management
- **Watchtower**: Auto-update containers
- **Ctop**: Container monitoring
- **Dozzle**: Log viewer

## Troubleshooting

### Container keeps restarting

```bash
# Check logs
docker logs container_name

# Check exit code
docker inspect container_name --format='{{.State.ExitCode}}'
```

### Network issues

```bash
# Inspect network
docker network inspect network_name

# Create network
docker network create mynetwork
```

### Disk space

```bash
# Check disk usage
docker system df

# Clean up
docker system prune -a --volumes
```

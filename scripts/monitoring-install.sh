#!/bin/bash

# Monitoring Tools Installation Script
# Installs Uptime Kuma, Beszel, and Umami via Docker
# Run as root or with sudo

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BASE_DIR="/opt"
COMPOSE_DIR="/opt"

echo -e "${GREEN}=== Monitoring Tools Installation ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Install Uptime Kuma
install_uptime_kuma() {
    echo -e "${YELLOW}[1/3] Installing Uptime Kuma...${NC}"
    
    mkdir -p $BASE_DIR/uptime-kuma
    cd $BASE_DIR/uptime-kuma
    
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3002:3001"
    volumes:
      - uptime-kuma-data:/app/data
    environment:
      - TZ=UTC

volumes:
  uptime-kuma-data:
    name: uptime-kuma-data
EOF

    docker compose up -d
    echo -e "${GREEN}Uptime Kuma installed: http://localhost:3002${NC}"
}

# Install Beszel
install_beszel() {
    echo -e "${YELLOW}[2/3] Installing Beszel...${NC}"
    
    mkdir -p $BASE_DIR/beszel
    cd $BASE_DIR/beszel
    
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
      - beszel-data:/app/data
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - TZ=UTC

volumes:
  beszel-data:
    name: beszel-data
EOF

    docker compose up -d
    echo -e "${GREEN}Beszel installed: http://localhost:3003${NC}"
}

# Install Umami
install_umami() {
    echo -e "${YELLOW}[3/3] Installing Umami with PostgreSQL...${NC}"
    
    mkdir -p $BASE_DIR/umami
    cd $BASE_DIR/umami
    
    # Generate secure password
    UMAMI_PASSWORD=$(openssl rand -base64 16)
    
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
      - DATABASE_URL=postgresql://umami:${UMAMI_PASSWORD}@db:5432/umami
      - DATABASE_TYPE=postgresql
      - TZ=UTC
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    container_name: umami-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=umami
      - POSTGRES_USER=umami
      - POSTGRES_PASSWORD=${UMAMI_PASSWORD}
    volumes:
      - umami-db-data:/var/lib/postgresql/data

volumes:
  umami-db-data:
    name: umami-db-data
EOF

    # Save credentials
    cat > .env <<EOF
UMAMI_DB_PASSWORD=${UMAMI_PASSWORD}
EOF
    
    docker compose up -d
    echo -e "${GREEN}Umami installed: http://localhost:3001${NC}"
    echo -e "${YELLOW}Database password saved to $BASE_DIR/umami/.env${NC}"
}

# Main menu
echo ""
echo "Select monitoring tools to install:"
echo "1) Install all monitoring tools"
echo "2) Install Uptime Kuma only"
echo "3) Install Beszel only"
echo "4) Install Umami only"
echo "5) Exit"
echo ""

read -p "Enter option [1-5]: " option

case $option in
    1)
        install_uptime_kuma
        install_beszel
        install_umami
        ;;
    2)
        install_uptime_kuma
        ;;
    3)
        install_beszel
        ;;
    4)
        install_umami
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

# Verify installations
echo ""
echo -e "${GREEN}=== Verifying Installations ===${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Access your monitoring tools:"
echo "  - Uptime Kuma: http://your-server-ip:3002"
echo "  - Beszel:      http://your-server-ip:3003"
echo "  - Umami:       http://your-server-ip:3001"
echo ""
echo "Next steps:"
echo "1. Configure reverse proxy (Traefik) for SSL"
echo "2. Set up DNS records"
echo "3. Configure alert notifications"

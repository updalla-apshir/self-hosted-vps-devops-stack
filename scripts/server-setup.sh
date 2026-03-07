#!/bin/bash

# Production VPS Server Setup Script
# This script automates the initial server setup for a production VPS
# Run as root or with sudo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOYER_USER="deployer"
TIMEZONE="UTC"

echo -e "${GREEN}=== Production VPS Setup Script ===${NC}"
echo "Starting server configuration..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Update System
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt update && apt upgrade -y

# Install Basic Dependencies
echo -e "${YELLOW}[2/8] Installing basic dependencies...${NC}"
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    unzip

# Set Timezone
echo -e "${YELLOW}[3/8] Setting timezone...${NC}"
timedatectl set-timezone $TIMEZONE

# Create Deployer User
echo -e "${YELLOW}[4/8] Creating deployer user...${NC}"
if ! id "$DEPLOYER_USER" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo $DEPLOYER_USER
    echo "$DEPLOYER_USER:password" | chpasswd
    # Copy SSH keys
    if [ -d "/root/.ssh" ]; then
        cp -r /root/.ssh /home/$DEPLOYER_USER/
        chown -R $DEPLOYER_USER:$DEPLOYER_USER /home/$DEPLOYER_USER/.ssh
    fi
    echo -e "${GREEN}User $DEPLOYER_USER created successfully${NC}"
else
    echo -e "${YELLOW}User $DEPLOYER_USER already exists${NC}"
fi

# Configure SSH
echo -e "${YELLOW}[5/8] Configuring SSH...${NC}"
cat > /etc/ssh/sshd_config.d/custom.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
EOF
systemctl restart sshd

# Setup UFW Firewall
echo -e "${YELLOW}[6/8] Configuring firewall...${NC}"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
echo -e "${GREEN}Firewall configured${NC}"

# Install Docker
echo -e "${YELLOW}[7/8] Installing Docker...${NC}"

# Add Docker GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker
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

# Add user to docker group
usermod -aG docker $DEPLOYER_USER
systemctl enable docker

# Setup Swap (if needed)
echo -e "${YELLOW}[8/8] Checking swap space...${NC}"
if [ $(free -m | awk '/^Mem:/{print $2}') -lt 8000 ]; then
    if [ $(swapon --show | wc -l) -eq 0 ]; then
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
        echo -e "${GREEN}Swap file created${NC}"
    fi
fi

# Configure sysctl
cat > /etc/sysctl.d/99-custom.conf <<EOF
# Network optimizations
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048

# File limits
fs.file-max = 65536

# Memory
vm.swappiness = 10
EOF

sysctl -p

# Install Fail2Ban
systemctl enable fail2ban
systemctl start fail2ban

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Login as deployer: su - $DEPLOYER_USER"
echo "2. Install Dokploy: bash -c \"\$(curl -fsSL https://get.dokploy.com)\""
echo "3. Configure your domain DNS"
echo "4. Set up monitoring tools"
echo ""
echo -e "${YELLOW}Important: Change the deployer password!${NC}"

#!/bin/bash

# Automated Backup Script
# Backs up Docker volumes, databases, and configurations
# Run as root or with sudo

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Services to backup
SERVICES=(
    "dokploy"
    "uptime-kuma"
    "beszel"
    "umami-db"
)

echo -e "${GREEN}=== Automated Backup Script ===${NC}"
echo "Date: $(date)"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Create backup directory
mkdir -p $BACKUP_DIR

# Function to backup Docker volume
backup_volume() {
    local volume_name=$1
    local backup_name=$2
    
    echo -e "${YELLOW}Backing up volume: $volume_name${NC}"
    
    # Check if volume exists
    if docker volume ls -q | grep -q "^${volume_name}$"; then
        # Create temporary container to backup volume
        docker run --rm \
            -v ${volume_name}:/data \
            -v ${BACKUP_DIR}:/backup \
            alpine \
            tar czf /backup/${backup_name}_${DATE}.tar.gz -C /data . \
            2>/dev/null || true
        
        # Create metadata
        cat > ${BACKUP_DIR}/${backup_name}_${DATE}.json <<EOF
{
    "volume": "${volume_name}",
    "backup_date": "${DATE}",
    "size": "$(du -h ${BACKUP_DIR}/${backup_name}_${DATE}.tar.gz 2>/dev/null | cut -f1 || echo 'unknown')"
}
EOF
        
        echo -e "${GREEN}  ✓ Volume $volume_name backed up${NC}"
    else
        echo -e "${YELLOW}  ⚠ Volume $volume_name not found, skipping${NC}"
    fi
}

# Function to backup database
backup_database() {
    local container=$1
    local backup_name=$2
    
    echo -e "${YELLOW}Backing up database: $container${NC}"
    
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        # For PostgreSQL (Umami)
        if [ "$container" = "umami-db" ]; then
            docker exec $container pg_dumpall -U umami | gzip > ${BACKUP_DIR}/${backup_name}_${DATE}.sql.gz
            echo -e "${GREEN}  ✓ Database $container backed up${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ Container $container not found, skipping${NC}"
    fi
}

# Function to backup configuration files
backup_configs() {
    echo -e "${YELLOW}Backing up configuration files...${NC}"
    
    # Create configs backup directory
    mkdir -p ${BACKUP_DIR}/configs_${DATE}
    
    # Traefik configs
    if [ -d "/etc/traefik" ]; then
        cp -r /etc/traefik ${BACKUP_DIR}/configs_${DATE}/ || true
    fi
    
    # Docker configs
    if [ -d "/etc/docker" ]; then
        cp -r /etc/docker ${BACKUP_DIR}/configs_${DATE}/ || true
    fi
    
    # Create archive
    cd ${BACKUP_DIR}
    tar czf configs_${DATE}.tar.gz configs_${DATE}/
    rm -rf configs_${DATE}
    
    echo -e "${GREEN}  ✓ Configuration files backed up${NC}"
}

# Function to list backups
list_backups() {
    echo -e "${BLUE}=== Available Backups ===${NC}"
    ls -lh $BACKUP_DIR
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo -e "${YELLOW}Cleaning up backups older than $RETENTION_DAYS days...${NC}"
    find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -delete
    echo -e "${GREEN}  ✓ Old backups cleaned up${NC}"
}

# Function to restore backup
restore_backup() {
    echo -e "${BLUE}=== Restore Backup ===${NC}"
    echo "Available backups:"
    ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null || echo "No backups found"
    echo ""
    
    read -p "Enter backup file name to restore: " backup_file
    
    if [ -f "$BACKUP_DIR/$backup_file" ]; then
        read -p "Enter volume name to restore to: " volume_name
        
        # Stop containers using the volume
        docker stop $(docker ps -q --filter volume=$volume_name) 2>/dev/null || true
        
        # Restore
        docker run --rm \
            -v ${volume_name}:/data \
            -v ${BACKUP_DIR}:/backup \
            alpine \
            sh -c "rm -rf /data/* && tar xzf /backup/${backup_file} -C /data"
        
        echo -e "${GREEN}  ✓ Backup restored to volume $volume_name${NC}"
    else
        echo -e "${RED}Backup file not found${NC}"
    fi
}

# Main menu
case "${1:-full}" in
    full)
        echo -e "${BLUE}Running full backup...${NC}"
        
        # Backup each service volume
        backup_volume "dokploy" "dokploy"
        backup_volume "uptime-kuma" "uptime-kuma"
        backup_volume "beszel-data" "beszel"
        backup_volume "umami-db-data" "umami-db"
        
        # Backup databases
        backup_database "umami-db" "umami-db"
        
        # Backup configs
        backup_configs
        
        # Cleanup
        cleanup_old_backups
        
        echo ""
        echo -e "${GREEN}=== Backup Complete! ===${NC}"
        list_backups
        ;;
    
    volume)
        if [ -z "$2" ]; then
            echo "Usage: $0 volume <volume_name>"
            exit 1
        fi
        backup_volume "$2" "$2"
        ;;
    
    list)
        list_backups
        ;;
    
    cleanup)
        cleanup_old_backups
        ;;
    
    restore)
        restore_backup
        ;;
    
    *)
        echo "Usage: $0 {full|volume|list|cleanup|restore}"
        echo ""
        echo "Commands:"
        echo "  full     - Run full backup (default)"
        echo "  volume   - Backup specific volume"
        echo "  list     - List available backups"
        echo "  cleanup  - Remove old backups"
        echo "  restore  - Restore from backup"
        exit 1
        ;;
esac

# Send notification (optional)
if command -v curl &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Sending backup notification...${NC}"
    # Add your webhook URL here for notifications
    # curl -X POST "https://your-webhook.com/notify" -d "Backup completed: $DATE"
fi

echo ""
echo -e "${GREEN}Done!${NC}"

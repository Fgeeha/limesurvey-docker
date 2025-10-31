#!/bin/bash
# Database restore script for LimeSurvey PostgreSQL

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if backup file is provided
if [ -z "$1" ]; then
    log_error "Usage: $0 <backup_file.sql.gz>"
    log_info "Example: $0 backups/limesurvey_backup_20241031_020000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

log_warn "╔═══════════════════════════════════════════════════════════╗"
log_warn "║                    ⚠️  WARNING ⚠️                          ║"
log_warn "║                                                           ║"
log_warn "║  This will COMPLETELY REPLACE your current database!     ║"
log_warn "║  All existing data will be LOST!                         ║"
log_warn "║                                                           ║"
log_warn "╚═══════════════════════════════════════════════════════════╝"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log_info "Restore cancelled."
    exit 0
fi

log_info "Starting database restore from: $BACKUP_FILE"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    log_error ".env file not found!"
    exit 1
fi

# Stop LimeSurvey container
log_info "Stopping LimeSurvey container..."
docker compose stop limesurvey

# Drop and recreate database
log_info "Dropping existing database..."
docker compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"

log_info "Creating new database..."
docker compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $POSTGRES_DB;"

# Restore backup
log_info "Restoring backup..."
if gunzip -c "$BACKUP_FILE" | docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
    log_info "Database restore completed successfully!"
else
    log_error "Database restore failed!"
    exit 1
fi

# Start LimeSurvey container
log_info "Starting LimeSurvey container..."
docker compose start limesurvey

# Wait for LimeSurvey to be ready
log_info "Waiting for LimeSurvey to be ready..."
sleep 5

log_info "╔═══════════════════════════════════════════════════════════╗"
log_info "║          ✅ Restore completed successfully! ✅             ║"
log_info "╚═══════════════════════════════════════════════════════════╝"
log_info "You can now access LimeSurvey at: $PUBLIC_URL"

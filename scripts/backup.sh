#!/bin/sh
# Database backup script for LimeSurvey PostgreSQL

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/limesurvey_backup_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo "${YELLOW}[WARN]${NC} $1"
}

# Create backup directory if not exists
mkdir -p "${BACKUP_DIR}"

log_info "Starting database backup..."
log_info "Backup file: ${BACKUP_FILE}"

# Perform backup
if PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
    -h postgres \
    -U "${POSTGRES_USER}" \
    -d "${POSTGRES_DB}" \
    --format=plain \
    --no-owner \
    --no-acl | gzip > "${BACKUP_FILE}"; then

    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log_info "Backup completed successfully!"
    log_info "Backup size: ${BACKUP_SIZE}"
else
    log_error "Backup failed!"
    exit 1
fi

# Cleanup old backups
log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "limesurvey_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete

REMAINING_BACKUPS=$(find "${BACKUP_DIR}" -name "limesurvey_backup_*.sql.gz" -type f | wc -l)
log_info "Remaining backups: ${REMAINING_BACKUPS}"

# Create latest symlink
ln -sf "${BACKUP_FILE}" "${BACKUP_DIR}/limesurvey_latest.sql.gz"

log_info "Backup process completed!"

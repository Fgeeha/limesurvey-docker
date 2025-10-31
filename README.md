# LimeSurvey Docker Setup

Production-ready LimeSurvey deployment with PostgreSQL, automated backups, and monitoring.

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/Fgeeha/limesurvey-docker.git
cd limesurvey-docker

# Copy environment file
cp .env.example .env

# Edit .env with your settings
nano .env

# Start services
docker compose up -d

# Check logs
docker compose logs -f
```

Access LimeSurvey at `http://localhost:8080`

**Default credentials:**
- Username: `admin`
- Password: Check your `.env` file

## 📁 Repository Structure

```
limesurvey-docker/
├── .env.example              # Example environment variables
├── .env                      # Your environment variables (gitignored)
├── .gitignore               # Git ignore rules
├── docker-compose.yml       # Main compose file
├── docker-compose.prod.yml  # Production overrides
├── docker-compose.dev.yml   # Development overrides
├── README.md                # This file
├── DEPLOYMENT.md            # Deployment guide
├── backups/                 # Database backups (gitignored)
│   └── .gitkeep
├── config/                  # LimeSurvey config (gitignored)
│   └── .gitkeep
├── plugins/                 # Custom plugins
│   └── .gitkeep
├── upload/                  # Survey uploads (gitignored)
│   └── .gitkeep
├── nginx/                   # Nginx reverse proxy
│   ├── nginx.conf
│   └── ssl/                # SSL certificates (gitignored)
├── scripts/                # Utility scripts
│   ├── backup.sh           # Database backup script
│   ├── restore.sh          # Database restore script
│   └── health-check.sh     # Health check script
└── monitoring/             # Monitoring configs
    ├── prometheus.yml
    └── grafana/
        └── dashboards/
```

## 🔧 Configuration


## 🛠️ Management Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f [service_name]

# Restart service
docker compose restart [service_name]

# Execute commands in container
docker compose exec limesurvey bash
docker compose exec postgres psql -U limesurvey

# Backup database
./scripts/backup.sh

# Restore database
./scripts/restore.sh backups/backup-2024-10-31.sql.gz

# Health check
./scripts/health-check.sh
```

## 🔐 Security Best Practices

1. **Change default passwords** in `.env`
2. **Enable SSL/TLS** for production (see nginx config)
3. **Regular backups** - automated daily backups enabled
4. **Keep images updated** - check for updates weekly
5. **Restrict network access** - use firewall rules
6. **Monitor logs** - check for suspicious activity

## 📊 Monitoring

Services include:
- Health checks for all containers
- Prometheus metrics (optional)
- Log aggregation
- Backup monitoring

## 🚢 Production Deployment

For production deployment:

```bash
# Use production compose file
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed production setup including:
- SSL/TLS configuration
- Reverse proxy setup
- Automated backups
- Monitoring setup
- Security hardening

## 🔄 Upgrades

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Check logs
docker compose logs -f
```

**Important:** Always backup before upgrading!

## 🐛 Troubleshooting

### Container won't start
```bash
docker compose logs [service_name]
```

### Database connection issues
```bash
docker compose exec postgres pg_isready -U limesurvey
```

### Reset admin password
```bash
docker compose exec limesurvey php application/commands/console.php resetpassword admin newpassword
```

## 📝 Development

Development environment with hot-reload:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

# Makefile for LimeSurvey Docker

.PHONY: help setup start stop restart logs backup restore clean health update

# Colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

# Default target
.DEFAULT_GOAL := help

## Help
help: ## Show this help message
	@echo ''
	@echo '${GREEN}LimeSurvey Docker Management${RESET}'
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-15s${RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Setup
setup: ## Initial setup - create .env from .env.example
	@if [ -f .env ]; then \
		echo "${YELLOW}⚠️  .env file already exists${RESET}"; \
		read -p "Do you want to overwrite it? (y/N): " confirm && [ $$confirm = y ] || exit 1; \
	fi
	@cp .env.example .env
	@echo "${GREEN}✅ .env file created${RESET}"
	@echo "${YELLOW}⚠️  Please edit .env and update passwords!${RESET}"

## Start/Stop
start: ## Start all services
	@echo "${GREEN}Starting LimeSurvey...${RESET}"
	@docker compose up -d
	@echo "${GREEN}✅ LimeSurvey started${RESET}"
	@echo "Access at: http://localhost:8080"

start-prod: ## Start with production config
	@echo "${GREEN}Starting LimeSurvey (Production)...${RESET}"
	@docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
	@echo "${GREEN}✅ LimeSurvey started in production mode${RESET}"

stop: ## Stop all services
	@echo "${YELLOW}Stopping LimeSurvey...${RESET}"
	@docker compose down
	@echo "${GREEN}✅ LimeSurvey stopped${RESET}"

restart: ## Restart all services
	@echo "${YELLOW}Restarting LimeSurvey...${RESET}"
	@docker compose restart
	@echo "${GREEN}✅ LimeSurvey restarted${RESET}"

## Logs
logs: ## Show logs for all services
	@docker compose logs -f

logs-app: ## Show logs for LimeSurvey app
	@docker compose logs -f limesurvey

logs-db: ## Show logs for database
	@docker compose logs -f postgres

## Backup/Restore
backup: ## Create database backup
	@echo "${GREEN}Creating backup...${RESET}"
	@chmod +x scripts/backup.sh
	@docker compose exec -T postgres sh /backup.sh
	@echo "${GREEN}✅ Backup completed${RESET}"

restore: ## Restore database from backup (usage: make restore FILE=backups/backup.sql.gz)
	@if [ -z "$(FILE)" ]; then \
		echo "${YELLOW}Usage: make restore FILE=backups/backup.sql.gz${RESET}"; \
		exit 1; \
	fi
	@chmod +x scripts/restore.sh
	@./scripts/restore.sh $(FILE)

list-backups: ## List all backups
	@echo "${GREEN}Available backups:${RESET}"
	@ls -lh backups/*.sql.gz 2>/dev/null || echo "No backups found"

## Maintenance
health: ## Check health status of services
	@echo "${GREEN}Checking service health...${RESET}"
	@docker compose ps
	@echo ""
	@echo "${GREEN}Container health checks:${RESET}"
	@docker compose exec postgres pg_isready -U limesurvey || echo "${YELLOW}Database not ready${RESET}"
	@curl -s http://localhost:8080/index.php > /dev/null && echo "${GREEN}✅ LimeSurvey is responding${RESET}" || echo "${YELLOW}⚠️  LimeSurvey not responding${RESET}"

update: ## Update to latest images
	@echo "${YELLOW}Pulling latest images...${RESET}"
	@docker compose pull
	@echo "${GREEN}Restarting services...${RESET}"
	@docker compose up -d
	@echo "${GREEN}✅ Update completed${RESET}"

clean: ## Remove stopped containers and unused volumes
	@echo "${YELLOW}Cleaning up...${RESET}"
	@docker compose down -v --remove-orphans
	@echo "${GREEN}✅ Cleanup completed${RESET}"

prune: ## Deep clean - remove all unused Docker resources
	@echo "${YELLOW}⚠️  This will remove all unused Docker resources${RESET}"
	@read -p "Are you sure? (y/N): " confirm && [ $$confirm = y ] || exit 1
	@docker system prune -af --volumes
	@echo "${GREEN}✅ Deep clean completed${RESET}"

## Database
db-shell: ## Open PostgreSQL shell
	@docker compose exec postgres psql -U limesurvey -d limesurvey

db-dump: ## Create SQL dump of database
	@echo "${GREEN}Creating SQL dump...${RESET}"
	@docker compose exec -T postgres pg_dump -U limesurvey limesurvey > dump_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "${GREEN}✅ Dump created${RESET}"

## Development
shell: ## Open bash shell in LimeSurvey container
	@docker compose exec limesurvey bash

shell-db: ## Open bash shell in database container
	@docker compose exec postgres bash

## Monitoring
stats: ## Show container resource usage
	@docker stats --no-stream

inspect: ## Show detailed container information
	@docker compose ps -a
	@echo ""
	@docker compose config

## Production
prod-deploy: setup start-prod ## Full production deployment
	@echo "${GREEN}✅ Production deployment completed${RESET}"
	@echo "Don't forget to:"
	@echo "  1. Configure SSL certificates"
	@echo "  2. Set up firewall rules"
	@echo "  3. Enable automated backups"
	@echo "  4. Configure monitoring"
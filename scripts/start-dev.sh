#!/bin/bash

# HKD Exchange - Start Development Environment
# This script starts all infrastructure services for local development

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 HKD Exchange - Starting Development Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check if .env file exists, if not create from .env.example
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found, creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ Created .env file${NC}"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Pulling latest Docker images...${NC}"
docker-compose pull

echo ""
echo -e "${BLUE}🏗️  Starting infrastructure services...${NC}"
echo ""

# Start services in order
echo -e "${GREEN}[1/5] Starting databases (PostgreSQL, TimescaleDB, MongoDB)...${NC}"
docker-compose up -d postgres-primary postgres-replica timescaledb mongodb

echo -e "${GREEN}[2/5] Starting cache and message queue (Redis, Kafka, Zookeeper)...${NC}"
docker-compose up -d redis-node-1 redis-node-2 redis-node-3 zookeeper kafka

echo -e "${GREEN}[3/5] Starting service registry and config (Nacos, MySQL)...${NC}"
docker-compose up -d mysql-nacos nacos

echo -e "${GREEN}[4/5] Starting distributed transaction coordinator (Seata)...${NC}"
docker-compose up -d seata-server

echo -e "${GREEN}[5/5] Starting monitoring and management tools...${NC}"
docker-compose up -d prometheus grafana skywalking-oap skywalking-ui kafka-ui adminer nginx

echo ""
echo -e "${BLUE}⏳ Waiting for services to be healthy...${NC}"
echo ""

# Wait for critical services
echo -n "  Waiting for PostgreSQL..."
timeout 60 bash -c 'until docker-compose exec -T postgres-primary pg_isready -U hkd_admin -d hkd_main > /dev/null 2>&1; do sleep 1; done' && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo -n "  Waiting for TimescaleDB..."
timeout 60 bash -c 'until docker-compose exec -T timescaledb pg_isready -U hkd_admin -d hkd_market > /dev/null 2>&1; do sleep 1; done' && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo -n "  Waiting for MongoDB..."
timeout 60 bash -c 'until docker-compose exec -T mongodb mongosh --eval "db.adminCommand(\"ping\")" > /dev/null 2>&1; do sleep 1; done' && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo -n "  Waiting for Kafka..."
timeout 90 bash -c 'until docker-compose exec -T kafka kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1; do sleep 1; done' && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo -n "  Waiting for Nacos..."
timeout 90 bash -c 'until curl -sf http://localhost:8848/nacos/v1/console/health/readiness > /dev/null 2>&1; do sleep 1; done' && echo -e " ${GREEN}✓${NC}" || echo -e " ${RED}✗${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Development environment started successfully!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Initialize Redis Cluster (run once)
echo -e "${YELLOW}🔧 Initializing Redis Cluster (if not already initialized)...${NC}"
docker-compose up -d redis-cluster-init || true
sleep 5
echo ""

# Print service information
echo -e "${BLUE}📊 Service Information:${NC}"
echo ""
echo -e "${GREEN}Databases:${NC}"
echo "  • PostgreSQL (Primary):  postgresql://localhost:5432"
echo "  • PostgreSQL (Replica):  postgresql://localhost:5433"
echo "  • TimescaleDB:           postgresql://localhost:5434"
echo "  • MongoDB:               mongodb://localhost:27017"
echo "  • Redis Cluster:         redis://localhost:6379, 6380, 6381"
echo ""
echo -e "${GREEN}Message Queue:${NC}"
echo "  • Kafka:                 localhost:9093 (external)"
echo "  • Zookeeper:             localhost:2181"
echo "  • Kafka UI:              http://localhost:8080"
echo ""
echo -e "${GREEN}Service Registry & Config:${NC}"
echo "  • Nacos:                 http://localhost:8848/nacos"
echo "    Username: nacos, Password: nacos"
echo ""
echo -e "${GREEN}Distributed Transaction:${NC}"
echo "  • Seata Server:          localhost:8091"
echo ""
echo -e "${GREEN}Monitoring & Management:${NC}"
echo "  • Prometheus:            http://localhost:9090"
echo "  • Grafana:               http://localhost:3000"
echo "    Username: admin, Password: hkd_grafana_2024"
echo "  • Skywalking UI:         http://localhost:8082"
echo "  • Adminer (DB UI):       http://localhost:8081"
echo "    Server: postgres-primary, User: hkd_admin, Password: hkd_dev_password_2024"
echo ""
echo -e "${GREEN}API Gateway:${NC}"
echo "  • Nginx:                 http://localhost:80"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📝 Quick Commands:${NC}"
echo ""
echo "  View logs:       ./scripts/logs.sh [service-name]"
echo "  Stop services:   ./scripts/stop-dev.sh"
echo "  Reset all data:  ./scripts/reset-dev.sh"
echo "  Service status:  docker-compose ps"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎯 Ready for development! Start your Claude Code instances.${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

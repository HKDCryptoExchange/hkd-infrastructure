#!/bin/bash

# HKD Exchange - Reset Development Environment
# ⚠️  WARNING: This will DELETE ALL DATA!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}⚠️  WARNING: DESTRUCTIVE OPERATION${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  • Stop all services"
echo "  • Remove all containers"
echo "  • Delete all data volumes (PostgreSQL, Redis, MongoDB, etc.)"
echo "  • Reset to fresh state"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${GREEN}Operation cancelled.${NC}"
    exit 0
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}Stopping all services...${NC}"
docker-compose down -v --remove-orphans

echo ""
echo -e "${BLUE}Removing all volumes...${NC}"
docker volume ls -q | grep hkd-infrastructure | xargs -r docker volume rm || true

echo ""
echo -e "${GREEN}✅ Environment reset complete${NC}"
echo ""
echo -e "${YELLOW}To start fresh environment:${NC}"
echo -e "  ./scripts/start-dev.sh"
echo ""

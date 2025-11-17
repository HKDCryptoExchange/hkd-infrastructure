#!/bin/bash

# HKD Exchange - View Service Logs

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo ""
    echo "Available services:"
    docker-compose ps --services | sort
    echo ""
    echo "Examples:"
    echo "  $0 postgres-primary"
    echo "  $0 kafka"
    echo "  $0 nacos"
    echo ""
    echo "To view all logs:"
    echo "  docker-compose logs -f"
    exit 1
fi

docker-compose logs -f "$1"

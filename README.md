# HKD Exchange - Infrastructure & Development Environment

This repository contains the unified development environment for all HKD Exchange microservices. It provides all infrastructure services via Docker Compose, allowing multiple Claude Code instances to share a single, consistent environment.

## 📦 Included Services

### Databases
- **PostgreSQL 16** (Primary + Replica): Main relational database
  - Primary: `localhost:5432`
  - Replica: `localhost:5433`
  - Pre-configured databases for all microservices
- **TimescaleDB**: Time-series database for market data (K-lines, trades)
  - Port: `localhost:5434`
  - Pre-configured hypertables with retention policies
- **MongoDB 7**: Audit logs and unstructured data
  - Port: `localhost:27017`

### Cache & Message Queue
- **Redis 7.2 Cluster**: 3-node cluster for caching and sessions
  - Ports: `localhost:6379`, `6380`, `6381`
- **Kafka 3.6 + Zookeeper**: Message queue for async communication
  - Kafka: `localhost:9092` (internal), `localhost:9093` (external)
  - Zookeeper: `localhost:2181`
  - Kafka UI: `http://localhost:8080`

### Service Registry & Config
- **Nacos 2.3**: Service discovery and config management
  - Web UI: `http://localhost:8848/nacos`
  - Credentials: `nacos` / `nacos`

### Distributed Transaction
- **Seata Server 2.0**: Distributed transaction coordinator
  - Port: `localhost:8091`

### Monitoring & APM
- **Prometheus**: Metrics collection
  - Web UI: `http://localhost:9090`
- **Grafana**: Monitoring dashboards
  - Web UI: `http://localhost:3000`
  - Credentials: `admin` / `hkd_grafana_2024`
- **Skywalking 9.6**: APM and distributed tracing
  - Web UI: `http://localhost:8082`

### Management Tools
- **Adminer**: Database management web UI
  - Web UI: `http://localhost:8081`
  - Server: `postgres-primary`, User: `hkd_admin`, Password: `hkd_dev_password_2024`
- **Kafka UI**: Kafka management web UI
  - Web UI: `http://localhost:8080`
- **Nginx**: Reverse proxy and load balancer
  - HTTP: `localhost:80`

---

## 🚀 Quick Start

### Prerequisites

- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Minimum**: 8GB RAM, 20GB disk space
- **Recommended**: 16GB RAM, 50GB disk space

### Installation

1. **Clone this repository**:
   ```bash
   cd /home/judy/codebase/HKD
   git clone git@github.com:HKDCryptoExchange/hkd-infrastructure.git
   cd hkd-infrastructure
   ```

2. **Start the development environment**:
   ```bash
   ./scripts/start-dev.sh
   ```

   This will:
   - Pull all Docker images
   - Start all services in the correct order
   - Wait for services to be healthy
   - Initialize databases
   - Display connection information

3. **Verify services are running**:
   ```bash
   docker-compose ps
   ```

   You should see all services with status `Up` or `Up (healthy)`.

---

## 📖 Usage

### Starting the Environment

```bash
./scripts/start-dev.sh
```

**First-time startup** may take 5-10 minutes to pull images and initialize databases.

### Stopping the Environment

```bash
./scripts/stop-dev.sh
```

This stops all services but **preserves data** in volumes.

### Viewing Logs

```bash
# View logs for a specific service
./scripts/logs.sh postgres-primary
./scripts/logs.sh kafka
./scripts/logs.sh nacos

# View all logs
docker-compose logs -f
```

### Resetting Environment

⚠️ **WARNING**: This deletes all data!

```bash
./scripts/reset-dev.sh
```

Use this when you need a fresh start.

---

## 🔌 Connection Information

### Database Connections

**PostgreSQL (Primary)**:
```
Host: localhost
Port: 5432
User: hkd_admin
Password: hkd_dev_password_2024
Databases:
  - hkd_user, hkd_kyc, hkd_auth (User Domain)
  - hkd_account, hkd_wallet, hkd_deposit, hkd_withdraw, hkd_asset (Asset Domain)
  - hkd_trading, hkd_order, hkd_settlement (Trading Domain)
  - hkd_risk (Risk Domain)
  - hkd_gateway, hkd_notify, hkd_admin (Infrastructure)
```

**PostgreSQL (Replica)**: Same as primary but port `5433` (for read queries)

**TimescaleDB**:
```
Host: localhost
Port: 5434
User: hkd_admin
Password: hkd_dev_password_2024
Database: hkd_market
Tables: klines, market_trades, depth_snapshots (hypertables)
```

**MongoDB**:
```
URI: mongodb://hkd_admin:hkd_mongo_2024@localhost:27017/hkd_audit
Database: hkd_audit
```

**Redis Cluster**:
```
Nodes: localhost:6379, localhost:6380, localhost:6381
Password: hkd_redis_2024
Mode: Cluster
```

### Message Queue

**Kafka**:
```
Bootstrap Servers: localhost:9093
Internal: kafka:9092 (from Docker network)
Topics: Auto-created on first publish
```

### Service Registry

**Nacos**:
```
URL: http://localhost:8848/nacos
Username: nacos
Password: nacos
Namespace: public (default)
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   HKD Development Environment                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  PostgreSQL  │  │ TimescaleDB  │  │   MongoDB    │       │
│  │   Primary    │  │  (K-lines)   │  │ (Audit Logs) │       │
│  │   :5432      │  │   :5434      │  │   :27017     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │    Redis     │  │    Kafka     │  │    Nacos     │       │
│  │   Cluster    │  │ + Zookeeper  │  │  (Registry)  │       │
│  │ :6379/80/81  │  │ :9092/:9093  │  │   :8848      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Prometheus  │  │   Grafana    │  │  Skywalking  │       │
│  │ (Metrics)    │  │ (Dashboard)  │  │    (APM)     │       │
│  │   :9090      │  │   :3000      │  │   :8082      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
              ┌─────────────┴─────────────┐
              │                           │
    ┌─────────▼────────┐       ┌─────────▼────────┐
    │  Instance 2      │       │  Instance 3      │
    │  User Services   │  ...  │  Asset Services  │
    │  (8001-8003)     │       │  (8002-8008)     │
    └──────────────────┘       └──────────────────┘
```

---

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key variables:
- `POSTGRES_PASSWORD`: PostgreSQL admin password
- `REDIS_PASSWORD`: Redis cluster password
- `MONGO_PASSWORD`: MongoDB password
- `GRAFANA_ADMIN_PASSWORD`: Grafana admin password

### Database Initialization

SQL scripts in `init-scripts/` are automatically executed on first startup:
- `init-scripts/postgresql/01-init-databases.sql`: Creates all microservice databases
- `init-scripts/timescaledb/01-init-timescaledb.sql`: Creates hypertables for market data

### Service Configuration

Custom configurations in `config/`:
- `config/prometheus/prometheus.yml`: Prometheus scrape configs for all microservices
- `config/nginx/`: Nginx reverse proxy configs
- `config/seata/`: Seata distributed transaction configs

---

## 📊 Monitoring

### Prometheus Metrics

All Java microservices expose metrics at `/actuator/prometheus` (Spring Boot Actuator).

Example targets configured:
- User Domain: `hkd-user-service:8001`, `hkd-kyc-service:8003`, `hkd-auth-service:8013`
- Asset Domain: `hkd-account-service:8002`, `hkd-wallet-service:8008`, etc.
- Trading Domain: `hkd-order-gateway:8100`, `hkd-settlement-service:8101`
- Market Domain: `hkd-market-service:8010`
- Risk Domain: `hkd-risk-service:8011`, `hkd-ml-service:5000`

### Grafana Dashboards

Pre-configured dashboards (to be added):
- JVM metrics (heap, GC, threads)
- Database connection pools
- Kafka lag and throughput
- Redis performance

### Skywalking APM

Automatic distributed tracing for:
- Java services (via SkyWalking Java Agent)
- Go services (via SkyWalking Go Agent)
- Database queries
- HTTP requests

---

## 🗄️ Data Persistence

All data is stored in Docker volumes:
- `postgres-primary-data`: PostgreSQL primary database
- `postgres-replica-data`: PostgreSQL replica
- `timescaledb-data`: TimescaleDB market data
- `redis-1-data`, `redis-2-data`, `redis-3-data`: Redis cluster nodes
- `mongodb-data`: MongoDB audit logs
- `kafka-data`, `zookeeper-data`: Kafka and Zookeeper
- `mysql-nacos-data`: Nacos configuration
- `prometheus-data`, `grafana-data`: Monitoring data

**Data is preserved** across container restarts. To delete all data, run `./scripts/reset-dev.sh`.

---

## 🛠️ Troubleshooting

### Services Won't Start

1. **Check Docker is running**:
   ```bash
   docker info
   ```

2. **Check port conflicts**:
   ```bash
   # Find process using port 5432
   lsof -i :5432
   ```

3. **View service logs**:
   ```bash
   ./scripts/logs.sh <service-name>
   ```

### Database Connection Issues

1. **Verify database is healthy**:
   ```bash
   docker-compose exec postgres-primary pg_isready -U hkd_admin
   ```

2. **Check credentials**:
   - User: `hkd_admin`
   - Password: `hkd_dev_password_2024` (from `.env`)

3. **Reset database**:
   ```bash
   ./scripts/reset-dev.sh
   ./scripts/start-dev.sh
   ```

### Redis Cluster Issues

Redis cluster initialization may fail on first run. Fix:

```bash
# Remove Redis containers and volumes
docker-compose down -v
docker volume ls | grep redis | xargs docker volume rm

# Restart
./scripts/start-dev.sh
```

### Kafka Issues

1. **Check Kafka is running**:
   ```bash
   docker-compose exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092
   ```

2. **View Kafka logs**:
   ```bash
   ./scripts/logs.sh kafka
   ```

3. **Use Kafka UI**: `http://localhost:8080`

---

## 🚦 Service Health Checks

All critical services have health checks:

```bash
# Check all service health
docker-compose ps

# Individual health check examples
docker-compose exec postgres-primary pg_isready
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
docker-compose exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092
curl http://localhost:8848/nacos/v1/console/health/readiness
```

---

## 📚 Additional Resources

- **Project Management**: [hkd-project-management](https://github.com/HKDCryptoExchange/hkd-project-management)
- **Documentation**: [HKD_library_docs_only](https://github.com/HKDCryptoExchange/HKD_library_docs_only)
- **Multi-Instance Guide**: [MULTI-INSTANCE-SETUP-GUIDE.md](https://github.com/HKDCryptoExchange/hkd-project-management/blob/main/MULTI-INSTANCE-SETUP-GUIDE.md)
- **Repository Index**: [REPOSITORY-INDEX.md](https://github.com/HKDCryptoExchange/hkd-project-management/blob/main/REPOSITORY-INDEX.md)

---

## 🤝 Contributing

This infrastructure is shared across all HKD microservice development.

When adding new services:
1. Add Prometheus scrape config in `config/prometheus/prometheus.yml`
2. Update this README with new service information
3. Commit and push to GitHub

---

## 📝 License

MIT License - HKD Exchange Project

---

## 🆘 Support

For issues and questions:
- GitHub Issues: [hkd-infrastructure/issues](https://github.com/HKDCryptoExchange/hkd-infrastructure/issues)
- Documentation: See links above

---

**Last Updated**: 2025-11-17
**Maintained By**: Instance 1 (Project Management)

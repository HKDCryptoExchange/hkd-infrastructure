-- HKD Exchange - PostgreSQL Database Initialization
-- This script creates all databases and schemas for microservices

-- ============================================================
-- Create Databases for Each Domain
-- ============================================================

-- User Domain
CREATE DATABASE hkd_user;
CREATE DATABASE hkd_kyc;
CREATE DATABASE hkd_auth;

-- Asset Domain
CREATE DATABASE hkd_account;
CREATE DATABASE hkd_wallet;
CREATE DATABASE hkd_deposit;
CREATE DATABASE hkd_withdraw;
CREATE DATABASE hkd_asset;

-- Trading Domain
CREATE DATABASE hkd_trading;
CREATE DATABASE hkd_order;
CREATE DATABASE hkd_settlement;

-- Market Domain (will use TimescaleDB separately)
-- CREATE DATABASE hkd_market;  -- Moved to TimescaleDB

-- Risk Domain
CREATE DATABASE hkd_risk;

-- Infrastructure
CREATE DATABASE hkd_gateway;
CREATE DATABASE hkd_notify;
CREATE DATABASE hkd_admin;

-- Skywalking APM
CREATE DATABASE skywalking;

-- ============================================================
-- Grant Permissions
-- ============================================================

GRANT ALL PRIVILEGES ON DATABASE hkd_user TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_kyc TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_auth TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_account TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_wallet TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_deposit TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_withdraw TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_asset TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_trading TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_order TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_settlement TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_risk TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_gateway TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_notify TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE hkd_admin TO hkd_admin;
GRANT ALL PRIVILEGES ON DATABASE skywalking TO hkd_admin;

-- ============================================================
-- Print Success Message
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '✅ HKD Exchange databases initialized successfully';
    RAISE NOTICE 'Total databases created: 16';
    RAISE NOTICE 'Admin user: hkd_admin';
END $$;

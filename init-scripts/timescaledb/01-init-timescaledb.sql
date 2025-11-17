-- HKD Exchange - TimescaleDB Initialization for Market Data
-- This script creates hypertables for K-line and trade data

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- ============================================================
-- Create K-line Table (Hypertable)
-- ============================================================

CREATE TABLE IF NOT EXISTS klines (
    id BIGSERIAL,
    symbol VARCHAR(20) NOT NULL,           -- e.g., BTCUSDT
    interval VARCHAR(10) NOT NULL,         -- e.g., 1m, 5m, 15m, 30m, 1h, 4h, 1d, 1w, 1M
    open_time TIMESTAMPTZ NOT NULL,
    close_time TIMESTAMPTZ NOT NULL,
    open_price DECIMAL(20, 8) NOT NULL,
    high_price DECIMAL(20, 8) NOT NULL,
    low_price DECIMAL(20, 8) NOT NULL,
    close_price DECIMAL(20, 8) NOT NULL,
    volume DECIMAL(20, 8) NOT NULL,
    quote_volume DECIMAL(20, 8) NOT NULL,
    trades_count INTEGER NOT NULL,
    taker_buy_base_volume DECIMAL(20, 8),
    taker_buy_quote_volume DECIMAL(20, 8),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (symbol, interval, open_time)
);

-- Convert to hypertable (partitioned by open_time)
SELECT create_hypertable('klines', 'open_time', if_not_exists => TRUE);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_klines_symbol_interval ON klines (symbol, interval, open_time DESC);
CREATE INDEX IF NOT EXISTS idx_klines_close_time ON klines (close_time DESC);

-- ============================================================
-- Create Market Trades Table (Hypertable)
-- ============================================================

CREATE TABLE IF NOT EXISTS market_trades (
    id BIGSERIAL,
    trade_id BIGINT NOT NULL UNIQUE,
    symbol VARCHAR(20) NOT NULL,
    price DECIMAL(20, 8) NOT NULL,
    quantity DECIMAL(20, 8) NOT NULL,
    quote_quantity DECIMAL(20, 8) NOT NULL,
    time TIMESTAMPTZ NOT NULL,
    is_buyer_maker BOOLEAN NOT NULL,
    is_best_match BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (symbol, time, trade_id)
);

-- Convert to hypertable
SELECT create_hypertable('market_trades', 'time', if_not_exists => TRUE);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_market_trades_symbol ON market_trades (symbol, time DESC);
CREATE INDEX IF NOT EXISTS idx_market_trades_trade_id ON market_trades (trade_id);

-- ============================================================
-- Create Depth Snapshot Table (Hypertable)
-- ============================================================

CREATE TABLE IF NOT EXISTS depth_snapshots (
    id BIGSERIAL,
    symbol VARCHAR(20) NOT NULL,
    snapshot_time TIMESTAMPTZ NOT NULL,
    bids JSONB NOT NULL,                  -- Array of [price, quantity]
    asks JSONB NOT NULL,                  -- Array of [price, quantity]
    last_update_id BIGINT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (symbol, snapshot_time)
);

-- Convert to hypertable
SELECT create_hypertable('depth_snapshots', 'snapshot_time', if_not_exists => TRUE);

-- Create index
CREATE INDEX IF NOT EXISTS idx_depth_snapshots_symbol ON depth_snapshots (symbol, snapshot_time DESC);

-- ============================================================
-- Data Retention Policies (keep 5 years)
-- ============================================================

-- K-line data retention
SELECT add_retention_policy('klines', INTERVAL '5 years', if_not_exists => TRUE);

-- Market trades retention (1 year for detailed trades)
SELECT add_retention_policy('market_trades', INTERVAL '1 year', if_not_exists => TRUE);

-- Depth snapshots retention (1 month)
SELECT add_retention_policy('depth_snapshots', INTERVAL '1 month', if_not_exists => TRUE);

-- ============================================================
-- Continuous Aggregates for Pre-computed Views (Optional)
-- ============================================================

-- 1-hour aggregated K-lines from 1-minute data (for faster queries)
CREATE MATERIALIZED VIEW IF NOT EXISTS klines_1h_agg
WITH (timescaledb.continuous) AS
SELECT
    symbol,
    time_bucket('1 hour', open_time) AS bucket,
    FIRST(open_price, open_time) AS open_price,
    MAX(high_price) AS high_price,
    MIN(low_price) AS low_price,
    LAST(close_price, open_time) AS close_price,
    SUM(volume) AS volume,
    SUM(quote_volume) AS quote_volume,
    SUM(trades_count) AS trades_count
FROM klines
WHERE interval = '1m'
GROUP BY symbol, bucket;

-- Refresh policy for continuous aggregate
SELECT add_continuous_aggregate_policy('klines_1h_agg',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE);

-- ============================================================
-- Print Success Message
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '✅ TimescaleDB initialized successfully for HKD Market Service';
    RAISE NOTICE 'Hypertables created: klines, market_trades, depth_snapshots';
    RAISE NOTICE 'Retention policies: 5 years (klines), 1 year (trades), 1 month (depth)';
    RAISE NOTICE 'Continuous aggregates: klines_1h_agg';
END $$;

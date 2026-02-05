-- PostgreSQL Database Setup for Smart Robot Monitor
-- This script creates the database, user, and schema

-- Step 1: Create the database and user (run as postgres superuser)
-- Note: You'll need to run this part separately with CREATE DATABASE permissions

-- CREATE DATABASE robot_monitor_db;
-- CREATE USER robot_user WITH PASSWORD 'your_secure_password';
-- GRANT ALL PRIVILEGES ON DATABASE robot_monitor_db TO robot_user;

-- Step 2: Connect to the database and create schema
-- Run: \c robot_monitor_db

-- Create the main telemetry table
CREATE TABLE IF NOT EXISTS robot_telemetry (
    timestamp TIMESTAMPTZ NOT NULL,      -- When data was recorded
    robot_id VARCHAR(50) NOT NULL,       -- Robot identifier
    battery_level FLOAT NOT NULL,        -- 0-100%
    temperature_celsius FLOAT NOT NULL,  -- Degrees Celsius
    status_code INT,                     -- 0=OK, 1=Warn, 2=Error
    PRIMARY KEY (timestamp, robot_id)
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_timestamp ON robot_telemetry(timestamp);
CREATE INDEX IF NOT EXISTS idx_robot_id ON robot_telemetry(robot_id);

-- Grant permissions to robot_user
GRANT ALL PRIVILEGES ON TABLE robot_telemetry TO robot_user;

-- Display confirmation
SELECT 'Database schema created successfully!' as status;

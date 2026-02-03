# Database Schema

This directory contains all database-related files for the Robot Monitor project.

## Directory Structure

- `schemas/` - SQL table definitions
- `migrations/` - Database migration scripts

## Setup Instructions

### 1. Create Database

Connect to your Vultr PostgreSQL instance and create the database:

```bash
ssh user@your-vultr-ip
sudo -u postgres psql
```

```sql
CREATE DATABASE robot_monitor_db;
CREATE USER robot_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE robot_monitor_db TO robot_user;
```

### 2. Create Schema

Run the schema creation script:

```bash
psql -h your-vultr-ip -U robot_user -d robot_monitor_db -f schemas/robot_telemetry.sql
```

### 3. Verify Setup

```sql
\c robot_monitor_db
\dt
SELECT * FROM robot_telemetry LIMIT 5;
```

## Schema Overview

### `robot_telemetry` Table

Stores time-series telemetry data from robots:

| Column                | Type         | Description                    |
|-----------------------|--------------|--------------------------------|
| timestamp             | TIMESTAMPTZ  | When data was recorded         |
| robot_id              | VARCHAR(50)  | Unique robot identifier        |
| battery_level         | FLOAT        | Battery percentage (0-100)     |
| temperature_celsius   | FLOAT        | Temperature in Celsius         |
| status_code           | INT          | Status code (0=OK, 1=Warn, 2=Error) |

Indexes:
- Primary key on (timestamp, robot_id)
- Index on timestamp for time-based queries
- Index on robot_id for filtering

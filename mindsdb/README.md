# MindsDB Configuration

This directory contains MindsDB setup files and SQL queries.

## Directory Structure

- `queries/` - SQL queries for creating views, models, and running reports
- `models/` - Configuration files for ML/AI models

## Setup Steps

### 1. Connect MindsDB to PostgreSQL

Access MindsDB (via web UI or SQL client):

```sql
CREATE DATABASE postgresql_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "localhost",
    "port": 5432,
    "database": "robot_monitor_db",
    "user": "robot_user",
    "password": "your_password"
};
```

### 2. Create Anomaly Detection View

Run `queries/create_view.sql`:

```sql
CREATE VIEW anomalous_robots AS
SELECT * FROM postgresql_db.robot_telemetry
WHERE battery_level < 20 OR temperature_celsius > 80
ORDER BY timestamp DESC;
```

### 3. Set Up Gemini Model

Run `queries/create_gemini_model.sql` (after adding your API key):

```sql
CREATE MODEL gemini_robot_reporter
PREDICT report
USING
    engine = 'gemini',
    api_key = 'your_gemini_api_key',
    prompt_template = 'A robot named {{robot_id}} has triggered an alert...';
```

### 4. Query for AI Reports

Run `queries/query_alerts.sql`:

```sql
SELECT
    r.robot_id,
    r.battery_level,
    r.temperature_celsius,
    r.timestamp,
    g.report
FROM anomalous_robots AS r
JOIN gemini_robot_reporter AS g;
```

## Accessing MindsDB

- **Web UI**: http://your-vultr-ip:47334
- **SQL Client**: Connect to port 47335 using MySQL protocol
- **HTTP API**: http://your-vultr-ip:47334/api

## Troubleshooting

- If connection fails, check PostgreSQL allows remote connections
- Verify Gemini API key is valid and has quota
- Check MindsDB logs: `docker logs mindsdb` (if using Docker)

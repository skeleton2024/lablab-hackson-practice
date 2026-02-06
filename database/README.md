# Database Configuration

This directory contains the PostgreSQL database schema for the Smart Robot Monitor project.

## Files in This Directory

### [`setup_database.sql`](./setup_database.sql)
**Database schema creation script** - Sets up the complete PostgreSQL database structure for storing robot telemetry data.

**What it does:**
- **Creates the `robot_telemetry` table**: Main table for storing time-series robot data
- **Defines data constraints**: Ensures data integrity with proper column types and checks
- **Creates indexes**: Optimizes query performance for timestamp and robot_id lookups
- **Sets up permissions**: Grants necessary privileges to the robot_user

**Table Structure:**

| Column                | Type         | Description                           | Constraints                    |
|-----------------------|--------------|---------------------------------------|--------------------------------|
| `id`                  | SERIAL       | Auto-incrementing primary key         | PRIMARY KEY                    |
| `timestamp`           | TIMESTAMP    | When the reading was recorded         | NOT NULL, DEFAULT NOW()        |
| `robot_id`            | VARCHAR(50)  | Unique robot identifier               | NOT NULL                       |
| `battery_level`       | DECIMAL(5,2) | Battery percentage (0-100)            | NOT NULL, CHECK (0-100)        |
| `temperature_celsius` | DECIMAL(5,2) | Temperature in Celsius                | NOT NULL                       |
| `status_code`         | INTEGER      | Robot status (0=OK, 1=WARNING, 2=ERROR) | NOT NULL, CHECK (0, 1, 2)     |
| `created_at`          | TIMESTAMP    | Record creation timestamp             | DEFAULT NOW()                  |

**Indexes:**
- `idx_robot_telemetry_timestamp` - Fast time-based queries
- `idx_robot_telemetry_robot_id` - Fast filtering by robot
- `idx_robot_telemetry_status` - Fast filtering by status code

## Setup Instructions

### Prerequisites

1. ✅ **Vultr Server**: Ubuntu server deployed with SSH access
2. ✅ **PostgreSQL Installed**: Version 12 or higher
3. ✅ **Database User Created**: `robot_user` with appropriate permissions

### Option 1: Quick Setup (Recommended)

If you're following the main tutorial, the database setup is integrated into Part 2. Simply run:

```bash
# SSH into your Vultr server
ssh root@your-vultr-ip

# Switch to postgres user
sudo -i -u postgres

# Create the database
createdb robot_monitor_db

# Create user
psql -c "CREATE USER robot_user WITH PASSWORD 'your_secure_password';"

# Grant privileges
psql -c "GRANT ALL PRIVILEGES ON DATABASE robot_monitor_db TO robot_user;"

# Run the schema script
psql -d robot_monitor_db -f /path/to/setup_database.sql

# Exit postgres user
exit
```

### Option 2: Manual Setup

1. **Connect to PostgreSQL**:
   ```bash
   sudo -u postgres psql
   ```

2. **Create Database and User**:
   ```sql
   CREATE DATABASE robot_monitor_db;
   CREATE USER robot_user WITH PASSWORD 'your_secure_password';
   GRANT ALL PRIVILEGES ON DATABASE robot_monitor_db TO robot_user;
   \q
   ```

3. **Run the Schema Script**:
   ```bash
   sudo -u postgres psql -d robot_monitor_db -f setup_database.sql
   ```

### Verify Setup

```bash
# Connect to the database
psql -h localhost -U robot_user -d robot_monitor_db

# List tables
\dt

# View table structure
\d robot_telemetry

# Check if any data exists
SELECT COUNT(*) FROM robot_telemetry;

# Exit
\q
```

## Configuration for Remote Access

To allow the Python simulator and MindsDB to connect remotely:

### 1. Edit PostgreSQL Configuration

```bash
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Change:
```
listen_addresses = '*'
```

### 2. Edit Client Authentication

```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Add:
```
host    all             all             0.0.0.0/0            md5
```

### 3. Configure Firewall

```bash
sudo ufw allow 5432/tcp
sudo systemctl restart postgresql
```

### 4. Test Remote Connection

From your local machine:
```bash
psql -h your-vultr-ip -U robot_user -d robot_monitor_db
```

## Sample Queries

### View Latest Readings
```sql
SELECT * FROM robot_telemetry
ORDER BY timestamp DESC
LIMIT 10;
```

### Check Robot Status
```sql
SELECT
    robot_id,
    COUNT(*) as total_readings,
    AVG(battery_level) as avg_battery,
    AVG(temperature_celsius) as avg_temp,
    MAX(timestamp) as last_reading
FROM robot_telemetry
GROUP BY robot_id;
```

### Find Anomalies
```sql
SELECT * FROM robot_telemetry
WHERE battery_level < 20 OR temperature_celsius > 80
ORDER BY timestamp DESC;
```

### Battery Drain Analysis
```sql
SELECT
    robot_id,
    DATE_TRUNC('hour', timestamp) as hour,
    MIN(battery_level) as min_battery,
    MAX(battery_level) as max_battery,
    MAX(battery_level) - MIN(battery_level) as drain_rate
FROM robot_telemetry
GROUP BY robot_id, hour
ORDER BY hour DESC;
```

## Maintenance

### Backup Database
```bash
pg_dump -h your-vultr-ip -U robot_user robot_monitor_db > backup_$(date +%Y%m%d).sql
```

### Restore Database
```bash
psql -h your-vultr-ip -U robot_user -d robot_monitor_db < backup_20250101.sql
```

### Clear Old Data (Optional)
```sql
-- Delete readings older than 30 days
DELETE FROM robot_telemetry
WHERE timestamp < NOW() - INTERVAL '30 days';

-- Vacuum to reclaim space
VACUUM ANALYZE robot_telemetry;
```

## Troubleshooting

### Connection Refused
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Verify firewall: `sudo ufw status`
- Confirm listen_addresses in postgresql.conf

### Permission Denied
- Ensure robot_user has proper grants
- Check pg_hba.conf has correct authentication method
- Verify password is correct in .env file

### Table Already Exists
- Drop and recreate: `DROP TABLE robot_telemetry CASCADE;`
- Or use the `IF NOT EXISTS` clause (already in setup_database.sql)

## Database Performance Tips

1. **Regular Vacuuming**: Run `VACUUM ANALYZE` weekly for optimal performance
2. **Index Maintenance**: Monitor index usage with `pg_stat_user_indexes`
3. **Partitioning**: For large datasets (>10M rows), consider time-based partitioning
4. **Connection Pooling**: Use PgBouncer for multiple simulators

## Next Steps

After setting up the database:

1. ✅ Configure your `.env` file with database credentials
2. ✅ Run the Python simulator to start generating data
3. ✅ Connect MindsDB to this database
4. ✅ Create AI models and agents in MindsDB

See the [main README](../README.md) for the complete tutorial.

---

💡 **Tip**: The schema is designed for time-series data. Consider adding data retention policies if you plan to run this long-term!

# PostgreSQL Database Setup Guide

This guide walks you through setting up the PostgreSQL database for the Smart Robot Monitor project.

## Prerequisites

- A Vultr cloud instance running Ubuntu 20.04 or later
- SSH access to the instance
- Root or sudo privileges

## Setup Options

### Option 1: Automated Setup (Recommended)

The automated script will install PostgreSQL, create the database, configure remote access, and set up firewall rules.

1. **Copy the setup script to your Vultr instance**:
   ```bash
   scp setup_postgres.sh root@YOUR_VULTR_IP:/root/
   ```

2. **SSH into your Vultr instance**:
   ```bash
   ssh root@YOUR_VULTR_IP
   ```

3. **Run the setup script**:
   ```bash
   cd /root
   chmod +x setup_postgres.sh
   sudo ./setup_postgres.sh
   ```

4. **Save the credentials** displayed at the end. You'll need them for the `.env` file.

5. **Test the connection from your local machine**:
   ```bash
   psql -h YOUR_VULTR_IP -U robot_user -d robot_monitor_db
   # Enter the password when prompted
   ```

### Option 2: Manual Setup

If you prefer to set up the database manually or already have PostgreSQL installed:

1. **Install PostgreSQL** (if not already installed):
   ```bash
   sudo apt update
   sudo apt install -y postgresql postgresql-contrib
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

2. **Create database and user**:
   ```bash
   sudo -u postgres psql
   ```

   Then in the PostgreSQL prompt:
   ```sql
   CREATE DATABASE robot_monitor_db;
   CREATE USER robot_user WITH PASSWORD 'your_secure_password';
   GRANT ALL PRIVILEGES ON DATABASE robot_monitor_db TO robot_user;
   \q
   ```

3. **Create the schema**:
   ```bash
   sudo -u postgres psql -d robot_monitor_db -f setup_database.sql
   ```

4. **Configure remote access**:

   Edit `/etc/postgresql/[VERSION]/main/postgresql.conf`:
   ```bash
   sudo nano /etc/postgresql/14/main/postgresql.conf
   ```

   Add or uncomment:
   ```
   listen_addresses = '*'
   ```

   Edit `/etc/postgresql/[VERSION]/main/pg_hba.conf`:
   ```bash
   sudo nano /etc/postgresql/14/main/pg_hba.conf
   ```

   Add:
   ```
   host    robot_monitor_db    robot_user    0.0.0.0/0    md5
   ```

5. **Configure firewall**:
   ```bash
   sudo ufw allow 5432/tcp
   ```

6. **Restart PostgreSQL**:
   ```bash
   sudo systemctl restart postgresql
   ```

## Database Schema

The database includes a single table for storing robot telemetry:

```sql
CREATE TABLE robot_telemetry (
    timestamp TIMESTAMPTZ NOT NULL,      -- When data was recorded
    robot_id VARCHAR(50) NOT NULL,       -- Robot identifier
    battery_level FLOAT NOT NULL,        -- 0-100%
    temperature_celsius FLOAT NOT NULL,  -- Degrees Celsius
    status_code INT,                     -- 0=OK, 1=Warn, 2=Error
    PRIMARY KEY (timestamp, robot_id)
);
```

Indexes:
- `idx_timestamp` - For time-range queries
- `idx_robot_id` - For per-robot filtering

## Configuration

After setup, update your local `.env` file:

```bash
cp .env.example .env
nano .env
```

Update these values:
```env
DB_HOST=YOUR_VULTR_IP
DB_PORT=5432
DB_NAME=robot_monitor_db
DB_USER=robot_user
DB_PASSWORD=your_secure_password
```

## Verification

Test the database connection:

```bash
# From your Vultr instance
sudo -u postgres psql -d robot_monitor_db -c "\dt"

# From your local machine
psql -h YOUR_VULTR_IP -U robot_user -d robot_monitor_db -c "\dt"
```

You should see the `robot_telemetry` table listed.

## Troubleshooting

### Cannot connect from local machine

1. **Check PostgreSQL is listening**:
   ```bash
   sudo netstat -plnt | grep 5432
   ```
   Should show `0.0.0.0:5432`

2. **Check firewall**:
   ```bash
   sudo ufw status
   ```
   Should show port 5432 allowed

3. **Check pg_hba.conf**:
   ```bash
   sudo cat /etc/postgresql/14/main/pg_hba.conf | grep robot_monitor_db
   ```

4. **Check PostgreSQL logs**:
   ```bash
   sudo tail -f /var/log/postgresql/postgresql-14-main.log
   ```

### Authentication failed

Make sure you're using the correct password. Reset it if needed:
```sql
sudo -u postgres psql
ALTER USER robot_user WITH PASSWORD 'new_password';
```

### Connection timeout

Check if the Vultr firewall is blocking port 5432. Go to your Vultr dashboard and ensure the firewall allows inbound connections on port 5432.

## Security Best Practices

1. **Use strong passwords**: Generate with `openssl rand -base64 32`
2. **Restrict access**: Limit `pg_hba.conf` to specific IP addresses instead of `0.0.0.0/0`
3. **Enable SSL**: Configure SSL/TLS for encrypted connections
4. **Regular backups**: Set up automated backups with `pg_dump`
5. **Monitor logs**: Regularly check PostgreSQL logs for suspicious activity

## Next Steps

Once the database is set up and verified:
1. Configure the Python simulator to connect to the database
2. Set up MindsDB to connect to PostgreSQL
3. Test the full data pipeline

See the main [README.md](../README.md) for the complete setup guide.

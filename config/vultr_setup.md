# Vultr Instance Setup Guide

This guide walks you through setting up a Vultr cloud instance for the Robot Monitor project.

## Step 1: Create Vultr Account

1. Go to https://www.vultr.com/
2. Sign up for an account
3. Add a payment method
4. Consider using promotional credits if available

## Step 2: Deploy Cloud Compute Instance

### Instance Configuration

1. **Choose Server Type**: Cloud Compute - Shared CPU
2. **Server Location**: Choose closest to you
3. **Server Image**: Ubuntu 22.04 LTS x64
4. **Server Size**:
   - Minimum: 2 vCPU, 4GB RAM, 80GB SSD ($18/month)
   - Recommended: 4 vCPU, 8GB RAM, 160GB SSD ($36/month)

5. **Additional Features**:
   - Enable IPv6 (optional)
   - Enable Auto Backups (recommended)
   - Add SSH Key (recommended for security)

6. **Server Hostname**: `robot-monitor-vultr`
7. **Deploy Now**

## Step 3: Initial Server Access

```bash
# SSH into your server
ssh root@your-vultr-ip

# Update system packages
apt update && apt upgrade -y

# Install basic utilities
apt install -y curl wget git vim ufw
```

## Step 4: Install PostgreSQL

```bash
# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL shell:
CREATE DATABASE robot_monitor_db;
CREATE USER robot_user WITH PASSWORD 'choose_secure_password';
GRANT ALL PRIVILEGES ON DATABASE robot_monitor_db TO robot_user;
\q
```

### Configure PostgreSQL for Remote Access

```bash
# Edit PostgreSQL config
vim /etc/postgresql/14/main/postgresql.conf

# Change: listen_addresses = 'localhost' to:
listen_addresses = '*'

# Edit pg_hba.conf
vim /etc/postgresql/14/main/pg_hba.conf

# Add this line:
host    all             all             0.0.0.0/0               md5

# Restart PostgreSQL
systemctl restart postgresql
```

## Step 5: Install MindsDB

### Option A: Using Docker (Recommended)

```bash
# Install Docker
apt install -y docker.io docker-compose
systemctl start docker
systemctl enable docker

# Run MindsDB container
docker run -d \
  --name mindsdb \
  -p 47334:47334 \
  -p 47335:47335 \
  -v ~/mindsdb_data:/root/mdb_storage \
  mindsdb/mindsdb:latest

# Check if running
docker ps
docker logs mindsdb
```

### Option B: Using pip

```bash
# Install Python and pip
apt install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv /opt/mindsdb-venv
source /opt/mindsdb-venv/bin/activate

# Install MindsDB
pip install mindsdb

# Run MindsDB
mindsdb --api=http,mysql
```

## Step 6: Configure Firewall

```bash
# Enable UFW
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp

# Allow PostgreSQL
ufw allow 5432/tcp

# Allow MindsDB
ufw allow 47334/tcp  # HTTP API
ufw allow 47335/tcp  # MySQL protocol

# Enable firewall
ufw enable

# Check status
ufw status
```

## Step 7: Verify Installation

### Test PostgreSQL

```bash
psql -h localhost -U robot_user -d robot_monitor_db
# Enter password
\l  # List databases
\q  # Quit
```

### Test MindsDB

```bash
# Access MindsDB web UI
curl http://localhost:47334

# Or visit in browser:
# http://your-vultr-ip:47334
```

## Step 8: Security Hardening (Optional but Recommended)

```bash
# Create non-root user
adduser appuser
usermod -aG sudo appuser

# Set up SSH key authentication
mkdir -p /home/appuser/.ssh
cp /root/.ssh/authorized_keys /home/appuser/.ssh/
chown -R appuser:appuser /home/appuser/.ssh
chmod 700 /home/appuser/.ssh
chmod 600 /home/appuser/.ssh/authorized_keys

# Disable root SSH login
vim /etc/ssh/sshd_config
# Set: PermitRootLogin no
systemctl restart sshd
```

## Step 9: Document Credentials

Save these in your `.env` file:

```
DB_HOST=your-vultr-ip
DB_PORT=5432
DB_NAME=robot_monitor_db
DB_USER=robot_user
DB_PASSWORD=your_password
MINDSDB_HOST=your-vultr-ip
MINDSDB_PORT=47334
```

## Troubleshooting

### Can't connect to PostgreSQL remotely
- Check firewall: `ufw status`
- Verify pg_hba.conf settings
- Ensure PostgreSQL is listening: `netstat -an | grep 5432`

### MindsDB container won't start
- Check Docker logs: `docker logs mindsdb`
- Ensure ports are available: `netstat -tuln | grep 47334`
- Try pulling latest image: `docker pull mindsdb/mindsdb:latest`

### Out of memory issues
- Upgrade to larger instance
- Add swap space: `fallocate -l 4G /swapfile && mkswap /swapfile && swapon /swapfile`

## Next Steps

Once your Vultr instance is set up:
1. ✅ PostgreSQL is running and accessible
2. ✅ MindsDB is running and accessible
3. ✅ Firewall is configured
4. ✅ Credentials are documented

Proceed to **Phase 2: Database Schema Design** in the main README.

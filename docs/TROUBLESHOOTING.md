# Troubleshooting Guide

Common issues and solutions for the Robot Monitor project.

---

## Database Connection Issues

### Issue: "Connection refused" when connecting to PostgreSQL

**Symptoms**:
```
psycopg2.OperationalError: could not connect to server: Connection refused
```

**Solutions**:

1. **Check PostgreSQL is running**:
```bash
systemctl status postgresql
```

2. **Verify PostgreSQL is listening on correct port**:
```bash
netstat -an | grep 5432
# Should show: 0.0.0.0:5432 or :::5432
```

3. **Check firewall**:
```bash
ufw status
# Should show: 5432 ALLOW
```

4. **Verify pg_hba.conf allows remote connections**:
```bash
sudo vim /etc/postgresql/14/main/pg_hba.conf
# Should have: host all all 0.0.0.0/0 md5
sudo systemctl restart postgresql
```

---

### Issue: "Password authentication failed"

**Symptoms**:
```
psycopg2.OperationalError: FATAL: password authentication failed for user "robot_user"
```

**Solutions**:

1. **Reset password**:
```bash
sudo -u postgres psql
ALTER USER robot_user WITH PASSWORD 'new_password';
\q
```

2. **Verify credentials in .env file**:
```bash
cat .env | grep DB_PASSWORD
```

3. **Test connection manually**:
```bash
psql -h your-vultr-ip -U robot_user -d robot_monitor_db
```

---

## MindsDB Issues

### Issue: MindsDB container won't start

**Symptoms**:
```
docker: Error response from daemon: Conflict. The container name "/mindsdb" is already in use
```

**Solutions**:

1. **Remove old container**:
```bash
docker stop mindsdb
docker rm mindsdb
docker run -d --name mindsdb -p 47334:47334 -p 47335:47335 mindsdb/mindsdb:latest
```

2. **Check logs**:
```bash
docker logs mindsdb
```

3. **Restart Docker**:
```bash
systemctl restart docker
```

---

### Issue: "Can't connect to MindsDB database"

**Symptoms**:
```
Error: Can't connect to MindsDB server on 'your-vultr-ip'
```

**Solutions**:

1. **Verify MindsDB is running**:
```bash
docker ps | grep mindsdb
curl http://localhost:47334
```

2. **Check firewall**:
```bash
ufw allow 47334/tcp
ufw allow 47335/tcp
```

3. **Test from inside Vultr instance first**:
```bash
curl http://localhost:47334
# If this works but remote doesn't, it's a firewall issue
```

---

### Issue: "Failed to create database connection in MindsDB"

**Symptoms**:
MindsDB can't connect to PostgreSQL

**Solutions**:

1. **Use 'localhost' not '127.0.0.1'** if MindsDB is on same server:
```sql
CREATE DATABASE postgresql_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "localhost",  -- Not 127.0.0.1
    "port": 5432,
    "database": "robot_monitor_db",
    "user": "robot_user",
    "password": "your_password"
};
```

2. **Check PostgreSQL allows local connections**:
```bash
sudo vim /etc/postgresql/14/main/pg_hba.conf
# Should have: host all all 127.0.0.1/32 md5
```

---

## Gemini API Issues

### Issue: "Invalid API key"

**Symptoms**:
```
Error: API key not valid. Please pass a valid API key.
```

**Solutions**:

1. **Verify API key**:
   - Go to https://makersuite.google.com/app/apikey
   - Generate new key if needed
   - Ensure no extra spaces when copying

2. **Check API key format**:
```sql
-- Should look like: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

3. **Verify Gemini API is enabled**:
   - Check Google AI Studio dashboard
   - Ensure API quotas are not exhausted

---

### Issue: "Rate limit exceeded"

**Symptoms**:
```
Error: 429 Too Many Requests
```

**Solutions**:

1. **Add delay between requests**:
```python
import time
time.sleep(2)  # Wait 2 seconds between queries
```

2. **Check quota limits**:
   - Go to Google AI Studio
   - Check your API usage
   - Upgrade plan if needed

3. **Use batch processing** instead of real-time queries

---

## Simulator Issues

### Issue: "ModuleNotFoundError: No module named 'psycopg2'"

**Solutions**:

1. **Activate virtual environment**:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

2. **Install psycopg2-binary**:
```bash
pip install psycopg2-binary
```

---

### Issue: Simulator runs but no data in database

**Solutions**:

1. **Check .env file exists and has correct values**:
```bash
cat .env
```

2. **Add debug prints to simulator**:
```python
print(f"Connecting to {os.getenv('DB_HOST')}...")
print(f"Inserted: {data}")
```

3. **Test database connection manually**:
```bash
psql -h your-vultr-ip -U robot_user -d robot_monitor_db
SELECT COUNT(*) FROM robot_telemetry;
```

---

## Query Issues

### Issue: "Table or view not found"

**Symptoms**:
```
Error: Table 'anomalous_robots' doesn't exist
```

**Solutions**:

1. **Create the view**:
```sql
CREATE VIEW anomalous_robots AS
SELECT * FROM postgresql_db.robot_telemetry
WHERE battery_level < 20 OR temperature_celsius > 80;
```

2. **Check database prefix**:
```sql
-- Use: postgresql_db.robot_telemetry
-- Not: robot_telemetry
```

3. **List available tables**:
```sql
SHOW TABLES FROM postgresql_db;
```

---

### Issue: "No anomalies detected"

**Symptoms**:
Query returns empty result set

**Solutions**:

1. **Lower thresholds temporarily**:
```sql
CREATE VIEW anomalous_robots AS
SELECT * FROM postgresql_db.robot_telemetry
WHERE battery_level < 50 OR temperature_celsius > 60;  -- More lenient
```

2. **Check if data exists**:
```sql
SELECT MIN(battery_level), MAX(battery_level),
       MIN(temperature_celsius), MAX(temperature_celsius)
FROM postgresql_db.robot_telemetry;
```

3. **Force anomaly in simulator**:
```python
# Temporarily set:
battery = 15  # Force low battery
temperature = 90  # Force high temp
```

---

## Performance Issues

### Issue: Queries are very slow

**Solutions**:

1. **Add indexes**:
```sql
CREATE INDEX idx_timestamp ON robot_telemetry(timestamp);
CREATE INDEX idx_robot_id ON robot_telemetry(robot_id);
CREATE INDEX idx_battery ON robot_telemetry(battery_level);
```

2. **Limit data retention**:
```sql
-- Delete old data
DELETE FROM robot_telemetry
WHERE timestamp < NOW() - INTERVAL '7 days';
```

3. **Upgrade Vultr instance** to more RAM/CPU

---

## Still Having Issues?

1. **Check logs**:
   - PostgreSQL: `/var/log/postgresql/`
   - MindsDB: `docker logs mindsdb`
   - Simulator: Add `logging` to Python script

2. **Test each component separately**:
   - Can you connect to PostgreSQL?
   - Does MindsDB respond to HTTP requests?
   - Does Gemini API work with curl?

3. **Start fresh**:
   - Drop and recreate database
   - Remove and restart MindsDB container
   - Verify .env file is correct

4. **Search MindsDB documentation**:
   - https://docs.mindsdb.com/

5. **Check Gemini API docs**:
   - https://ai.google.dev/docs

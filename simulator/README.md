# Robot Telemetry Simulator

This directory contains a Python-based robot telemetry simulator that generates realistic sensor data for testing and demonstration purposes.

## Files in This Directory

### 1. [`robot_simulator.py`](./robot_simulator.py)
**Main simulator script** - The core simulator that generates and sends robot telemetry data to PostgreSQL.

**What it does:**
- **Simulates Battery Drain**: Gradually drains from 100% to 0%, then auto-recharges
- **Generates Temperature Readings**: Uses normal distribution around 55°C
- **Injects Anomalies**: Randomly introduces low battery or high temperature issues
- **Database Integration**: Automatically inserts data into PostgreSQL with retry logic
- **Real-time Logging**: Color-coded console output with status indicators
- **Auto-reconnect**: Handles database connection failures gracefully

**Key Features:**
```python
class RobotSimulator:
    - generate_battery_level()      # Simulates gradual drain
    - generate_temperature()         # Normal distribution
    - inject_anomaly()               # Random problem injection
    - determine_status()             # 0=OK, 1=WARNING, 2=ERROR
    - _insert_telemetry_to_db()     # PostgreSQL insertion
    - run()                          # Main simulation loop
```

### 2. [`config.py`](./config.py)
**Configuration loader** - Loads settings from environment variables and provides default values.

**Configuration Variables:**
- **Database**: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- **Robot Settings**: `ROBOT_ID`, `DATA_INTERVAL_SECONDS`
- **Battery**: `INITIAL_BATTERY_LEVEL`, `BATTERY_DRAIN_RATE`, `BATTERY_ANOMALY_THRESHOLD`
- **Temperature**: `TEMPERATURE_MEAN`, `TEMPERATURE_STD_DEV`, `TEMPERATURE_MIN`, `TEMPERATURE_MAX`, `TEMPERATURE_ANOMALY_THRESHOLD`
- **Anomalies**: `ANOMALY_PROBABILITY`
- **Status Codes**: `STATUS_OK`, `STATUS_WARNING`, `STATUS_ERROR`

### 3. `__init__.py`
Python package initialization file.

## Quick Start

### 1. Install Dependencies

```bash
# From project root
pip install -r requirements.txt
```

**Required packages:**
- `psycopg2-binary` - PostgreSQL database adapter
- `python-dotenv` - Environment variable loader
- `pandas` - Data manipulation (optional)
- `colorama` - Colored terminal output

### 2. Configure Environment

Create a `.env` file in the project root:

```bash
# Copy the example
cp ../.env.example ../.env

# Edit with your credentials
nano ../.env
```

**Required variables:**
```env
DB_HOST=your_vultr_server_ip
DB_PORT=5432
DB_NAME=robot_monitor_db
DB_USER=robot_user
DB_PASSWORD=your_secure_password

ROBOT_ID=ROBOT-001
DATA_INTERVAL_SECONDS=5
BATTERY_DRAIN_RATE=0.5
ANOMALY_PROBABILITY=0.15
```

### 3. Run the Simulator

```bash
# From the simulator directory
python robot_simulator.py
```

**Expected Output:**
```
Initialized Robot Simulator for ROBOT-001
Configuration:
  - Data interval: 5s
  - Battery drain rate: 0.5% per reading
  - Anomaly probability: 15.0%
  - Battery anomaly threshold: <20%
  - Temperature anomaly threshold: >80°C
  - Database enabled: True
--------------------------------------------------------------------------------
Connecting to database at 45.76.123.456:5432...
✅ Database connection established successfully
--------------------------------------------------------------------------------
🤖 Starting robot telemetry simulation...
Press Ctrl+C to stop

[0001] Robot: ROBOT-001 | Battery:  99.50% | Temp: 56.34°C | Status: ✅ OK 💾
[0002] Robot: ROBOT-001 | Battery:  99.00% | Temp: 54.21°C | Status: ✅ OK 💾
[0003] Robot: ROBOT-001 | Battery:  98.50% | Temp: 57.89°C | Status: ✅ OK 💾
🔋 ANOMALY INJECTED: Low battery (18.2%)
[0004] Robot: ROBOT-001 | Battery:  18.20% | Temp: 55.67°C | Status: ⚠️  WARNING 💾
```

### 4. Stop the Simulator

Press `Ctrl+C` to gracefully stop the simulator.

## How It Works

### Data Generation Flow

```
1. Initialize Simulator
   ↓
2. Connect to Database
   ↓
3. Enter Simulation Loop:
   ├─ Generate battery level (drain gradually)
   ├─ Generate temperature (normal distribution)
   ├─ Maybe inject anomaly (based on probability)
   ├─ Determine status code (OK/WARNING/ERROR)
   ├─ Format telemetry data
   ├─ Insert into PostgreSQL
   ├─ Log to console
   └─ Wait for next interval
   ↓
4. Auto-recharge when battery reaches 0%
   ↓
5. Repeat from step 3
```

### Status Code Logic

```python
# Critical thresholds → ERROR (2)
if battery < 10 or temperature > 90:
    return STATUS_ERROR

# Warning thresholds → WARNING (1)
if battery < 20 or temperature > 80:
    return STATUS_WARNING

# Otherwise → OK (0)
return STATUS_OK
```

### Anomaly Injection

When an anomaly is injected (15% probability by default):
- **Low Battery**: Sets battery to 5-19%
- **High Temperature**: Sets temperature to 81-95°C
- **Both**: Combines low battery + high temperature

### Status Indicators

- ✅ **OK**: Normal operation (battery ≥ 20%, temperature ≤ 80°C)
- ⚠️ **WARNING**: Battery < 20% or Temperature > 80°C
- 🚨 **ERROR**: Battery < 10% or Temperature > 90°C
- 💾 **Database icon**: Successfully inserted to database

## Configuration Options

### Adjust Data Generation Speed

```env
# Generate data every 2 seconds (faster)
DATA_INTERVAL_SECONDS=2

# Generate data every 10 seconds (slower)
DATA_INTERVAL_SECONDS=10
```

### Increase Anomaly Rate

```env
# 50% chance of anomalies (for faster testing)
ANOMALY_PROBABILITY=0.5

# 5% chance (more realistic)
ANOMALY_PROBABILITY=0.05
```

### Change Battery Drain Rate

```env
# Faster drain (1% per reading)
BATTERY_DRAIN_RATE=1.0

# Slower drain (0.1% per reading)
BATTERY_DRAIN_RATE=0.1
```

### Simulate Multiple Robots

Run multiple instances with different robot IDs:

```bash
# Terminal 1
ROBOT_ID=ROBOT-001 python robot_simulator.py

# Terminal 2
ROBOT_ID=ROBOT-002 python robot_simulator.py

# Terminal 3
ROBOT_ID=ROBOT-003 python robot_simulator.py
```

Or modify `robot_simulator.py` to create multiple `RobotSimulator` instances.

## Testing Without Database

Run the simulator without database connectivity:

```python
# In robot_simulator.py, modify:
simulator = RobotSimulator(enable_db=False)
```

This will generate data and log to console only, useful for testing the logic.

## Advanced Usage

### Run for Limited Iterations

```python
# Modify main() function:
simulator.run(max_iterations=100)  # Stop after 100 readings
```

### Custom Anomaly Scenarios

Edit the `inject_anomaly()` method to create specific test scenarios:

```python
# Force low battery at iteration 50
if self.iteration == 50:
    battery = 15.0
    logger.warning("Forced low battery anomaly")
    return battery, temperature, True
```

## Troubleshooting

### Database Connection Failed

**Error:** `Failed to connect to database`

**Solutions:**
- Verify Vultr server IP in `.env`
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Confirm firewall allows port 5432
- Test manually: `psql -h your_ip -U robot_user -d robot_monitor_db`

### Module Not Found

**Error:** `ModuleNotFoundError: No module named 'psycopg2'`

**Solution:**
```bash
pip install -r ../requirements.txt
```

### Permission Denied

**Error:** `psycopg2.OperationalError: FATAL: permission denied`

**Solution:**
- Verify database user has correct privileges
- Check password in `.env` matches database
- Confirm `GRANT ALL PRIVILEGES` was executed

### Data Not Appearing in MindsDB

**Issue:** MindsDB shows no data

**Solutions:**
- Check simulator is running (look for 💾 icon)
- Verify data in PostgreSQL: `SELECT COUNT(*) FROM robot_telemetry;`
- Refresh MindsDB connection
- Check MindsDB database connection parameters

## Performance Tips

1. **Reduce Logging**: Set logging level to WARNING for production
2. **Batch Inserts**: For high-frequency data, batch multiple readings
3. **Connection Pooling**: Use `psycopg2.pool` for multiple simulators
4. **Async I/O**: Consider `asyncpg` for async operations

## Code Example: Custom Simulator

```python
from robot_simulator import RobotSimulator

# Create custom simulator
simulator = RobotSimulator(robot_id="ROBOT-CUSTOM")

# Run for specific duration
simulator.run(max_iterations=50)

# Clean up
simulator.close()
```

## Monitoring the Simulator

### Check Database Records
```bash
# Count total records
psql -h your_ip -U robot_user -d robot_monitor_db -c "SELECT COUNT(*) FROM robot_telemetry;"

# View latest readings
psql -h your_ip -U robot_user -d robot_monitor_db -c "SELECT * FROM robot_telemetry ORDER BY timestamp DESC LIMIT 5;"
```

### Monitor Anomalies
```bash
# Count anomalies
psql -h your_ip -U robot_user -d robot_monitor_db -c "SELECT COUNT(*) FROM robot_telemetry WHERE battery_level < 20 OR temperature_celsius > 80;"
```

## Next Steps

After running the simulator:

1. ✅ Verify data is being inserted into PostgreSQL
2. ✅ Connect MindsDB to query the telemetry data
3. ✅ Set up Gemini AI models for anomaly analysis
4. ✅ Create the robot monitoring agent

See the [main README](../README.md) for the complete tutorial.

---

💡 **Tip**: Let the simulator run for at least 10-15 minutes to generate enough data for meaningful AI analysis!

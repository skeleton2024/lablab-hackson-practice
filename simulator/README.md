# Robot Telemetry Simulator

This directory contains the Python script that simulates a robot generating telemetry data and inserting it into PostgreSQL.

## Features

- 🔋 Gradual battery drain simulation (100% → 0%)
- 🌡️ Temperature fluctuation with normal distribution
- ⚠️ Configurable anomaly injection (low battery, high temperature)
- 💾 Automatic database insertion
- 📊 Real-time logging with status indicators
- 🔄 Auto-recharge when battery depletes

## Files

- `robot_simulator.py` - Main simulator script with database connectivity
- `config.py` - Configuration settings loaded from environment variables
- `__init__.py` - Python package initialization

## Quick Start

### From Project Root

```bash
# Run using the convenience script
./run_simulator.sh
```

### Or Manually

```bash
# Install dependencies
pip3 install -r requirements.txt

# Run the simulator
cd simulator
python3 robot_simulator.py
```

## How It Works

The simulator generates realistic robot telemetry data:
- **Battery Level**: Gradually drains from 100% to 0%, then recharges
- **Temperature**: Fluctuates with normal distribution around 55°C
- **Status Code**: Integer representing robot state (0=OK, 1=WARNING, 2=ERROR)
- **Database**: Automatically inserts each reading into PostgreSQL

### Anomaly Generation

The simulator randomly injects anomalies:
- Low battery events (< 20%)
- High temperature events (> 80°C)
- Combined anomalies (both low battery and high temp)
- Configurable probability (default: 15%)

### Status Indicators

- ✅ **OK**: Normal operation
- ⚠️ **WARNING**: Battery < 20% or Temperature > 80°C
- 🚨 **ERROR**: Battery < 10% or Temperature > 90°C
- 💾 **Database icon**: Successfully inserted to database

## Configuration

Edit `.env` file in project root to configure:

```env
# Database Configuration (required)
DB_HOST=155.138.198.28
DB_PORT=5432
DB_NAME=robot_monitor_db
DB_USER=robot_user
DB_PASSWORD=RobotUser2024!Secure

# Robot Configuration
ROBOT_ID=ROBOT-001
DATA_INTERVAL_SECONDS=5
BATTERY_DRAIN_RATE=0.5
ANOMALY_PROBABILITY=0.15
```

## Sample Output

```
2026-02-05 14:01:38 - robot_simulator - INFO - Initialized Robot Simulator for ROBOT-001
2026-02-05 14:01:38 - robot_simulator - INFO - ✅ Database connection established successfully
2026-02-05 14:01:40 - robot_simulator - INFO - [0001] Robot: ROBOT-001 | Battery: 99.56% | Temp: 70.79°C | Status: ✅ OK 💾
2026-02-05 14:01:45 - robot_simulator - WARNING - ⚠️  ANOMALY INJECTED: High temperature (85.3°C)
2026-02-05 14:01:45 - robot_simulator - WARNING - [0002] Robot: ROBOT-001 | Battery: 99.06% | Temp: 85.30°C | Status: ⚠️  WARNING 💾
```

## Troubleshooting

### Database Connection Failed

Check your database credentials in `.env` and verify PostgreSQL is running:

```bash
psql -h 155.138.198.28 -U robot_user -d robot_monitor_db
```

### Module Not Found

Install dependencies:

```bash
pip3 install -r requirements.txt
```

### Test Without Database

```python
from robot_simulator import RobotSimulator
simulator = RobotSimulator(enable_db=False)
simulator.run(max_iterations=10)
```

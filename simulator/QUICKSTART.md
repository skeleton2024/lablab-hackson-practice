# Robot Simulator - Quick Start

## Running the Simulator

### Option 1: Limited Iterations (for testing)
```bash
cd /Users/la/Lablab-AI/vultr-mindsdb-gemini
python3 -c "
import sys
sys.path.insert(0, 'simulator')
from robot_simulator import RobotSimulator
sim = RobotSimulator()
sim.run(max_iterations=50)  # Run for 50 iterations then stop
"
```

### Option 2: Continuous Mode
```bash
cd /Users/la/Lablab-AI/vultr-mindsdb-gemini/simulator
python3 robot_simulator.py
```
Press `Ctrl+C` to stop.

## Configuration

Edit `.env` in the project root:
```bash
# Robot identifier
ROBOT_ID=ROBOT-001

# Data generation interval (seconds)
DATA_INTERVAL_SECONDS=5

# Battery drain rate (% per reading)
BATTERY_DRAIN_RATE=0.5

# Anomaly injection probability (0.0 to 1.0)
ANOMALY_PROBABILITY=0.15
```

## Output Examples

### Normal Operation
```
[0001] Robot: ROBOT-001 | Battery:  99.30% | Temp: 68.33°C | Status: ✅ OK
```

### Warning - Low Battery
```
🔋 ANOMALY INJECTED: Low battery (11.1%)
[0006] Robot: ROBOT-001 | Battery:  11.14% | Temp: 59.75°C | Status: ⚠️  WARNING
```

### Warning - High Temperature
```
🌡️  ANOMALY INJECTED: High temperature (88.7°C)
[0049] Robot: ROBOT-001 | Battery:  75.50% | Temp: 88.69°C | Status: ⚠️  WARNING
```

### Error - Critical Condition
```
⚠️  ANOMALY INJECTED: Low battery (8.4%) + High temperature (89.8°C)
[0003] Robot: ROBOT-001 | Battery:   8.36% | Temp: 89.84°C | Status: 🚨 ERROR
```

## Features Demonstrated

1. **Gradual Battery Drain**: Battery decreases by 0.5% per reading
2. **Temperature Fluctuation**: Normal distribution around 55°C (40-75°C range)
3. **Anomaly Injection**: 15% probability per reading
   - Low battery (< 20%)
   - High temperature (> 80°C)
   - Combined anomalies
4. **Status Classification**:
   - **OK** (0): Normal operation
   - **WARNING** (1): Battery < 20% OR Temp > 80°C
   - **ERROR** (2): Battery < 10% OR Temp > 90°C
5. **Auto-recharge**: When battery reaches 0%, it recharges to 100%

## Next Steps

After verifying the output:
1. Modify `robot_simulator.py` to insert data into PostgreSQL
2. Replace logging statements with database INSERT operations
3. Add error handling for database connections
4. Test with actual Vultr PostgreSQL instance
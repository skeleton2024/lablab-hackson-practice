# Robot Simulator

This directory contains the Python script that simulates a robot generating telemetry data.

## Files

- `robot_simulator.py` - Main simulator script that generates and sends telemetry data
- `config.py` - Configuration settings for the simulator
- `__init__.py` - Python package initialization

## How It Works

The simulator generates realistic robot telemetry data:
- **Battery Level**: Gradually drains from 100% to 0%
- **Temperature**: Fluctuates between 40-70°C normally, with occasional spikes
- **Status Code**: Integer representing robot state (0=OK, 1=Warning, 2=Error)

### Anomaly Generation

The simulator can inject anomalies:
- Low battery events (< 20%)
- High temperature events (> 80°C)
- Configurable probability of anomalies

## Usage

```bash
# Install dependencies
pip install -r ../requirements.txt

# Set up environment variables
cp ../.env.example ../.env
# Edit .env with your database credentials

# Run the simulator
python robot_simulator.py
```

## Configuration

Edit `.env` file to configure:
- `ROBOT_ID`: Unique identifier for the robot
- `DATA_INTERVAL_SECONDS`: How often to send data (default: 5)
- `ANOMALY_PROBABILITY`: Chance of generating anomalies (0.0 - 1.0)

"""
Configuration settings for the Robot Simulator.
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Robot Configuration
ROBOT_ID = os.getenv('ROBOT_ID', 'ROBOT-001')
DATA_INTERVAL_SECONDS = int(os.getenv('DATA_INTERVAL_SECONDS', '5'))

# Battery Simulation
INITIAL_BATTERY_LEVEL = 100.0
BATTERY_DRAIN_RATE = float(os.getenv('BATTERY_DRAIN_RATE', '0.5'))  # % per reading

# Temperature Simulation
TEMPERATURE_MEAN = 55.0  # Base temperature in Celsius
TEMPERATURE_STD_DEV = 8.0  # Standard deviation for normal distribution
TEMPERATURE_MIN = 40.0
TEMPERATURE_MAX = 75.0

# Anomaly Configuration
ANOMALY_PROBABILITY = float(os.getenv('ANOMALY_PROBABILITY', '0.15'))  # 15% chance
BATTERY_ANOMALY_THRESHOLD = 20.0  # Low battery threshold
TEMPERATURE_ANOMALY_THRESHOLD = 80.0  # High temperature threshold

# Status Codes
STATUS_OK = 0
STATUS_WARNING = 1
STATUS_ERROR = 2

# Logging Configuration
LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
LOG_DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

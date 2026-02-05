"""
Robot Telemetry Simulator

Generates realistic robot telemetry data with:
- Gradual battery drain
- Temperature fluctuations
- Configurable anomaly injection
"""

import logging
import random
import time
from datetime import datetime
from typing import Dict, Any

from config import (
    ROBOT_ID,
    DATA_INTERVAL_SECONDS,
    INITIAL_BATTERY_LEVEL,
    BATTERY_DRAIN_RATE,
    TEMPERATURE_MEAN,
    TEMPERATURE_STD_DEV,
    TEMPERATURE_MIN,
    TEMPERATURE_MAX,
    ANOMALY_PROBABILITY,
    BATTERY_ANOMALY_THRESHOLD,
    TEMPERATURE_ANOMALY_THRESHOLD,
    STATUS_OK,
    STATUS_WARNING,
    STATUS_ERROR,
    LOG_FORMAT,
    LOG_DATE_FORMAT
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format=LOG_FORMAT,
    datefmt=LOG_DATE_FORMAT
)
logger = logging.getLogger(__name__)


class RobotSimulator:
    """Simulates robot telemetry data generation."""

    def __init__(self, robot_id: str = ROBOT_ID):
        """
        Initialize the robot simulator.

        Args:
            robot_id: Unique identifier for the robot
        """
        self.robot_id = robot_id
        self.battery_level = INITIAL_BATTERY_LEVEL
        self.iteration = 0

        logger.info(f"Initialized Robot Simulator for {self.robot_id}")
        logger.info(f"Configuration:")
        logger.info(f"  - Data interval: {DATA_INTERVAL_SECONDS}s")
        logger.info(f"  - Battery drain rate: {BATTERY_DRAIN_RATE}% per reading")
        logger.info(f"  - Anomaly probability: {ANOMALY_PROBABILITY * 100}%")
        logger.info(f"  - Battery anomaly threshold: <{BATTERY_ANOMALY_THRESHOLD}%")
        logger.info(f"  - Temperature anomaly threshold: >{TEMPERATURE_ANOMALY_THRESHOLD}°C")
        logger.info("-" * 80)

    def generate_battery_level(self) -> float:
        """
        Generate battery level with gradual drain.

        Returns:
            Battery level as percentage (0-100)
        """
        # Drain battery gradually
        self.battery_level = max(0.0, self.battery_level - BATTERY_DRAIN_RATE)

        # Add small random fluctuation (-0.2 to +0.2)
        fluctuation = random.uniform(-0.2, 0.2)
        battery_with_fluctuation = self.battery_level + fluctuation

        # Ensure it stays within bounds
        return max(0.0, min(100.0, battery_with_fluctuation))

    def generate_temperature(self) -> float:
        """
        Generate temperature with normal distribution.

        Returns:
            Temperature in Celsius
        """
        # Generate temperature using normal distribution
        temp = random.gauss(TEMPERATURE_MEAN, TEMPERATURE_STD_DEV)

        # Clamp to realistic bounds
        return max(TEMPERATURE_MIN, min(TEMPERATURE_MAX, temp))

    def inject_anomaly(self, battery: float, temperature: float) -> tuple[float, float, bool]:
        """
        Randomly inject anomalies based on configured probability.

        Args:
            battery: Current battery level
            temperature: Current temperature

        Returns:
            Tuple of (modified_battery, modified_temperature, anomaly_injected)
        """
        if random.random() < ANOMALY_PROBABILITY:
            anomaly_type = random.choice(['battery', 'temperature', 'both'])

            if anomaly_type == 'battery':
                battery = random.uniform(5.0, BATTERY_ANOMALY_THRESHOLD - 1)
                logger.warning(f"🔋 ANOMALY INJECTED: Low battery ({battery:.1f}%)")
                return battery, temperature, True

            elif anomaly_type == 'temperature':
                temperature = random.uniform(TEMPERATURE_ANOMALY_THRESHOLD + 1, 95.0)
                logger.warning(f"🌡️  ANOMALY INJECTED: High temperature ({temperature:.1f}°C)")
                return battery, temperature, True

            else:  # both
                battery = random.uniform(5.0, BATTERY_ANOMALY_THRESHOLD - 1)
                temperature = random.uniform(TEMPERATURE_ANOMALY_THRESHOLD + 1, 95.0)
                logger.warning(f"⚠️  ANOMALY INJECTED: Low battery ({battery:.1f}%) + High temperature ({temperature:.1f}°C)")
                return battery, temperature, True

        return battery, temperature, False

    def determine_status(self, battery: float, temperature: float) -> int:
        """
        Determine status code based on telemetry values.

        Args:
            battery: Battery level percentage
            temperature: Temperature in Celsius

        Returns:
            Status code (0=OK, 1=WARNING, 2=ERROR)
        """
        # Critical thresholds
        if battery < 10 or temperature > 90:
            return STATUS_ERROR

        # Warning thresholds
        if battery < BATTERY_ANOMALY_THRESHOLD or temperature > TEMPERATURE_ANOMALY_THRESHOLD:
            return STATUS_WARNING

        return STATUS_OK

    def generate_telemetry(self) -> Dict[str, Any]:
        """
        Generate a complete telemetry data point.

        Returns:
            Dictionary containing telemetry data
        """
        self.iteration += 1

        # Generate base values
        battery = self.generate_battery_level()
        temperature = self.generate_temperature()

        # Potentially inject anomaly
        battery, temperature, anomaly_injected = self.inject_anomaly(battery, temperature)

        # Determine status
        status_code = self.determine_status(battery, temperature)

        # Create telemetry record
        telemetry = {
            'timestamp': datetime.now().isoformat(),
            'robot_id': self.robot_id,
            'battery_level': round(battery, 2),
            'temperature_celsius': round(temperature, 2),
            'status_code': status_code,
            'iteration': self.iteration,
            'anomaly_injected': anomaly_injected
        }

        return telemetry

    def format_telemetry_log(self, telemetry: Dict[str, Any]) -> str:
        """
        Format telemetry data for logging output.

        Args:
            telemetry: Telemetry data dictionary

        Returns:
            Formatted string for logging
        """
        status_map = {
            STATUS_OK: "✅ OK",
            STATUS_WARNING: "⚠️  WARNING",
            STATUS_ERROR: "🚨 ERROR"
        }

        status_text = status_map.get(telemetry['status_code'], "UNKNOWN")

        # Build log message
        log_parts = [
            f"[{telemetry['iteration']:04d}]",
            f"Robot: {telemetry['robot_id']}",
            f"| Battery: {telemetry['battery_level']:>6.2f}%",
            f"| Temp: {telemetry['temperature_celsius']:>5.2f}°C",
            f"| Status: {status_text}"
        ]

        return " ".join(log_parts)

    def run(self, max_iterations: int = None):
        """
        Run the simulator continuously.

        Args:
            max_iterations: Maximum number of iterations (None for infinite)
        """
        logger.info("🤖 Starting robot telemetry simulation...")
        logger.info(f"Press Ctrl+C to stop\n")

        try:
            iteration_count = 0
            while True:
                # Check if we've reached max iterations
                if max_iterations and iteration_count >= max_iterations:
                    logger.info(f"\n✅ Reached maximum iterations ({max_iterations})")
                    break

                # Generate telemetry
                telemetry = self.generate_telemetry()

                # Log the telemetry data
                log_message = self.format_telemetry_log(telemetry)

                if telemetry['status_code'] == STATUS_ERROR:
                    logger.error(log_message)
                elif telemetry['status_code'] == STATUS_WARNING:
                    logger.warning(log_message)
                else:
                    logger.info(log_message)

                # Log detailed JSON for verification (optional)
                logger.debug(f"Full telemetry: {telemetry}")

                # Reset battery when it reaches 0 (for continuous testing)
                if self.battery_level <= 0:
                    logger.info("\n" + "=" * 80)
                    logger.info("🔄 Battery depleted. Recharging to 100%...")
                    logger.info("=" * 80 + "\n")
                    self.battery_level = INITIAL_BATTERY_LEVEL

                # Wait for next iteration
                iteration_count += 1
                time.sleep(DATA_INTERVAL_SECONDS)

        except KeyboardInterrupt:
            logger.info("\n\n⏹️  Simulator stopped by user")
            logger.info(f"Total iterations: {self.iteration}")
            logger.info("Goodbye! 👋")


def main():
    """Main entry point for the simulator."""
    # Create and run simulator
    simulator = RobotSimulator()

    # Run indefinitely (or set max_iterations for testing)
    # simulator.run(max_iterations=50)  # For testing
    simulator.run()  # Run indefinitely


if __name__ == "__main__":
    main()
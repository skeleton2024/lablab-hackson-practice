#!/bin/bash

# Robot Simulator Startup Script
# This script starts the robot telemetry simulator

set -e

echo "🤖 Starting Robot Telemetry Simulator..."
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "Please copy .env.example to .env and configure your settings"
    exit 1
fi

# Check if Python dependencies are installed
if ! python3 -c "import psycopg2" 2>/dev/null; then
    echo "📦 Installing Python dependencies..."
    pip3 install -r requirements.txt
fi

echo "Starting simulator in 3 seconds..."
echo "Press Ctrl+C to stop"
echo ""
sleep 3

# Run the simulator
cd simulator
python3 robot_simulator.py

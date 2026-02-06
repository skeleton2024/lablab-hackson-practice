# MindsDB Configuration

This directory contains SQL scripts for setting up MindsDB with Google Gemini AI to create an intelligent robot monitoring system.

## Files in This Directory

### 1. [`mindsdb_setup.sql`](./mindsdb_setup.sql)
**Complete MindsDB setup script** - This is the main file you'll use to set up your entire AI monitoring system.

**What it does:**
- **Connects MindsDB to PostgreSQL**: Establishes connection to your Vultr database
- **Creates Anomaly Detection View**: Automatically filters robot readings where battery < 20% or temperature > 80°C
- **Sets Up Gemini AI Model**: Creates the `gemini_robot_reporter` model that generates maintenance reports
- **Generates AI Reports**: Provides queries to combine anomalies with AI analysis
- **Stores Historical Reports**: Creates persistent tables for anomaly reports
- **Includes Useful Queries**: Ready-to-use SQL for monitoring and analysis

**Usage:**
1. Open MindsDB SQL Editor at `http://localhost:47334`
2. Create a new tab
3. Copy the entire contents of this file
4. Update the connection parameters (host, password)
5. Run the script

### 2. [`create_agent.sql`](./create_agent.sql)
**Intelligent chatbot agent creation** - Creates a natural language agent that can answer questions about your robot fleet.

**What it does:**
- **Creates the Agent**: Sets up `robot_monitor_agent` with access to telemetry data
- **Connects Data Sources**: Links the agent to both the `robot_telemetry` table and `anomalous_robots` view
- **Enables Natural Language Queries**: Allows you to ask questions in plain English

**Usage:**
1. In MindsDB, navigate to the "Agents" folder
2. Click the three dots (...) and select "Create Agent"
3. Copy the contents of this file
4. Run the script
5. Go to "Chat with your data" to start asking questions

**Example questions you can ask the agent:**
- "What is the current status of ROBOT-001?"
- "How many anomalies occurred today?"
- "Should we schedule maintenance for any robots?"
- "What's the average battery level over the last hour?"

## Prerequisites

Before using these scripts:

1. ✅ **MindsDB Installed**: Via Docker or running locally
2. ✅ **PostgreSQL Database**: Robot telemetry database set up on Vultr
3. ✅ **Gemini API Key**: Configured in MindsDB Settings (Settings > Models > Default Model)
4. ✅ **Data Available**: Simulator running and generating telemetry data

## Setup Order

Follow this order for setup:

1. **Configure Gemini API** in MindsDB Settings first
2. **Run** `mindsdb_setup.sql` to set up the database connection and AI model
3. **Run** `create_agent.sql` to create the chatbot agent
4. **Test** by querying the agent in the Chat interface

## Quick Start Commands

### Connect to Your Database (from mindsdb_setup.sql)
```sql
CREATE DATABASE robot_postgres_db
WITH ENGINE = "postgres",
PARAMETERS = {
  "user": "robot_user",
  "password": "your_password",
  "host": "your_vultr_ip",
  "port": "5432",
  "database": "robot_monitor_db"
};
```

### Test Connection
```sql
SELECT * FROM robot_postgres_db.robot_telemetry
ORDER BY timestamp DESC
LIMIT 10;
```

### View Anomalies
```sql
SELECT * FROM anomalous_robots LIMIT 10;
```

### Get AI-Generated Report
```sql
SELECT
    a.robot_id,
    a.battery_level,
    a.temperature_celsius,
    a.severity,
    g.report
FROM anomalous_robots AS a
JOIN gemini_robot_reporter AS g
ORDER BY a.timestamp DESC
LIMIT 3;
```

## Accessing MindsDB

- **Web UI**: http://localhost:47334 (or your Vultr server IP)
- **SQL Editor**: Web UI → SQL Editor tab
- **Chat Interface**: Web UI → Chat with your data

## Troubleshooting

### Connection Issues
- Verify PostgreSQL allows remote connections
- Check firewall allows port 5432
- Confirm credentials match your `.env` file

### Gemini Model Not Working
- Ensure API key is configured in MindsDB Settings
- Verify model name is exactly `gemini-pro`
- Check you have API quota remaining

### No Anomalies Showing
- Let the simulator run longer (anomalies are randomly generated)
- Check anomalies exist: `SELECT * FROM robot_postgres_db.robot_telemetry WHERE battery_level < 20;`
- Increase `ANOMALY_PROBABILITY` in your simulator's `.env` file

## Additional Resources

- **MindsDB Documentation**: [docs.mindsdb.com](https://docs.mindsdb.com)
- **Gemini API Docs**: [ai.google.dev](https://ai.google.dev)
- **Main Tutorial**: See the [main README](../README.md) for the complete walkthrough

---

💡 **Tip**: Both SQL files are heavily commented. Open them to understand exactly what each query does!

# MindsDB Setup Guide

Complete guide for connecting MindsDB to your PostgreSQL database and setting up AI-powered robot monitoring.

## Prerequisites

- ✅ PostgreSQL database running with telemetry data
- ✅ MindsDB installed and running
- ⬜ Google Gemini API key ([Get one here](https://makersuite.google.com/app/apikey))

## Step 1: Configure Gemini API Key

Before running the SQL scripts, you need to configure your Gemini API key in MindsDB.

### Option A: Via MindsDB Web Interface

1. Open MindsDB in your browser (typically http://localhost:47334 or your Vultr IP)
2. Go to **Settings** → **Models** → **Default Model**
3. Configure:
   - **Provider**: Google
   - **Model Name**: gemini-pro
   - **API Key**: Your Gemini API key (starts with `AI...`)
4. Click **Save Preferences**

### Option B: Via SQL

```sql
CREATE ML_ENGINE gemini_engine
FROM gemini
USING
    gemini_api_key = 'YOUR_GEMINI_API_KEY';
```

## Step 2: Run MindsDB Setup Script

Open MindsDB's SQL editor and run the commands from `mindsdb_setup.sql`:

### 2.1 Connect to PostgreSQL

```sql
CREATE DATABASE robot_postgres_db
WITH ENGINE = "postgres",
PARAMETERS = {
  "user": "robot_user",
  "password": "RobotUser2024!Secure",
  "host": "155.138.198.28",
  "port": "5432",
  "database": "robot_monitor_db"
};
```

Verify the connection:

```sql
SELECT * FROM robot_postgres_db.robot_telemetry
ORDER BY timestamp DESC
LIMIT 10;
```

### 2.2 Create Anomaly Detection View

```sql
CREATE VIEW anomalous_robots AS
SELECT
    timestamp,
    robot_id,
    battery_level,
    temperature_celsius,
    status_code,
    CASE
        WHEN battery_level < 10 OR temperature_celsius > 90 THEN 'CRITICAL'
        WHEN battery_level < 20 OR temperature_celsius > 80 THEN 'WARNING'
        ELSE 'OK'
    END as severity,
    CASE
        WHEN battery_level < 20 AND temperature_celsius > 80 THEN 'Low Battery + High Temperature'
        WHEN battery_level < 20 THEN 'Low Battery'
        WHEN temperature_celsius > 80 THEN 'High Temperature'
        ELSE 'Normal'
    END as issue_type
FROM robot_postgres_db.robot_telemetry
WHERE battery_level < 20 OR temperature_celsius > 80
ORDER BY timestamp DESC;
```

Test the view:

```sql
SELECT * FROM anomalous_robots LIMIT 5;
```

### 2.3 Create Gemini AI Model

```sql
CREATE MODEL gemini_robot_reporter
PREDICT report
USING
    engine = 'gemini',
    model_name = 'gemini-pro',
    prompt_template = '
You are an expert robot maintenance analyst.
A robot has triggered an anomaly alert with the following telemetry:

Robot ID: {{robot_id}}
Timestamp: {{timestamp}}
Battery Level: {{battery_level}}%
Temperature: {{temperature_celsius}}°C
Severity: {{severity}}
Issue Type: {{issue_type}}

Please provide a concise maintenance report including:
1. SEVERITY ASSESSMENT: Rate the urgency (Low/Medium/High/Critical)
2. ROOT CAUSE: Explain the likely cause of this anomaly
3. IMMEDIATE ACTIONS: List 2-3 specific steps the maintenance team should take
4. RECOMMENDED ACTION: Choose one: CONTINUE_OPERATION / SCHEDULE_MAINTENANCE / RETURN_TO_BASE / EMERGENCY_STOP

Keep your response professional and actionable.
';
```

Check model status:

```sql
SELECT * FROM models WHERE name = 'gemini_robot_reporter';
```

Wait until status shows "complete" before proceeding.

## Step 3: Generate AI Reports

### Get AI Analysis for Latest Anomaly

```sql
SELECT
    a.timestamp,
    a.robot_id,
    a.battery_level,
    a.temperature_celsius,
    a.severity,
    a.issue_type,
    g.report as ai_maintenance_report
FROM anomalous_robots AS a
JOIN gemini_robot_reporter AS g
ORDER BY a.timestamp DESC
LIMIT 1;
```

### Generate Reports for All Recent Anomalies

```sql
SELECT
    a.timestamp,
    a.robot_id,
    a.battery_level,
    a.temperature_celsius,
    g.report
FROM anomalous_robots AS a
JOIN gemini_robot_reporter AS g
LIMIT 5;
```

## Step 4: Monitor in Real-Time

### Anomaly Statistics

```sql
SELECT
    issue_type,
    severity,
    COUNT(*) as count
FROM anomalous_robots
GROUP BY issue_type, severity
ORDER BY count DESC;
```

### Recent Activity (Last Hour)

```sql
SELECT
    COUNT(*) as active_anomalies,
    SUM(CASE WHEN severity = 'CRITICAL' THEN 1 ELSE 0 END) as critical_count,
    SUM(CASE WHEN severity = 'WARNING' THEN 1 ELSE 0 END) as warning_count
FROM anomalous_robots
WHERE timestamp > NOW() - INTERVAL 1 HOUR;
```

### Critical Issues with AI Analysis

```sql
SELECT
    a.robot_id,
    a.timestamp,
    a.battery_level,
    a.temperature_celsius,
    g.report
FROM anomalous_robots AS a
JOIN gemini_robot_reporter AS g
WHERE a.severity = 'CRITICAL'
ORDER BY a.timestamp DESC;
```

## Step 5: Create Chatbot Agent (Optional)

```sql
CREATE AGENT robot_monitor_agent
USING
    model = 'gemini_robot_reporter',
    data = {
        "tables": ['robot_postgres_db.robot_telemetry', 'anomalous_robots']
    };
```

Ask questions:

```sql
SELECT answer FROM robot_monitor_agent
WHERE question = 'What is the current status of ROBOT-001?';

SELECT answer FROM robot_monitor_agent
WHERE question = 'How many critical anomalies occurred today?';

SELECT answer FROM robot_monitor_agent
WHERE question = 'Should we schedule maintenance?';
```

## Troubleshooting

### Connection Failed

**Error**: `Connection to database failed`

**Solution**:
- Verify PostgreSQL is accessible from MindsDB
- Check credentials in the CREATE DATABASE statement
- Test connection manually: `psql -h 155.138.198.28 -U robot_user -d robot_monitor_db`

### Model Creation Failed

**Error**: `Failed to create model`

**Solution**:
- Verify Gemini API key is configured correctly
- Check API key has not exceeded quota
- Ensure model name is 'gemini-pro' (not 'gemini-1.5-pro')

### No Anomalies Found

**Error**: `anomalous_robots view returns no rows`

**Solution**:
- Run the simulator to generate more data with anomalies
- Lower the thresholds in the view definition
- Check if data exists: `SELECT COUNT(*) FROM robot_postgres_db.robot_telemetry;`

### AI Report Generation Slow

**Issue**: Queries take 2-3 seconds per anomaly

**Explanation**: This is normal - Gemini API calls take time. For production:
- Cache reports in a table (use `CREATE TABLE ... AS SELECT`)
- Generate reports asynchronously
- Use batch processing for multiple anomalies

## Best Practices

1. **Start Simple**: Test with 1-2 anomalies before generating bulk reports
2. **Monitor API Usage**: Gemini has rate limits (60 requests/minute on free tier)
3. **Store Reports**: Create a persistent table for historical analysis
4. **Customize Prompts**: Adjust the prompt_template to match your needs
5. **Regular Backups**: Back up your MindsDB configuration and data

## Next Steps

Once MindsDB is set up and generating AI reports:
1. Create a web dashboard for visualization
2. Set up automated alerts (email/Slack)
3. Implement predictive maintenance with ML models
4. Scale to multiple robots

See the main [README.md](../README.md) for the complete project roadmap.

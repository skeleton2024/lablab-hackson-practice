-- ============================================================================
-- MindsDB Setup for Smart Robot Monitor
-- ============================================================================
-- This SQL script connects MindsDB to your PostgreSQL database and sets up
-- AI-powered anomaly detection using Google Gemini.
--
-- Prerequisites:
--   1. MindsDB installed and running
--   2. PostgreSQL database with robot_telemetry data
--   3. Gemini API key configured in MindsDB Settings
--
-- Instructions:
--   * Go to MindsDB Settings > Models > Default Model
--   * Select "Google" provider, model "gemini-pro", and enter your API key
--   * Click "Save Preferences"
-- ============================================================================

---------------------
-- STEP 1: CONNECT TO POSTGRESQL DATABASE
---------------------
-- Connect MindsDB to your PostgreSQL database on Vultr
CREATE DATABASE robot_postgres_db
WITH ENGINE = "postgres",
PARAMETERS = {
  "user": "your_postgres_   user",
  "password": "your_postgres_password",
  "host": "your_postgres_host",
  "port": "5432",
  "database": "your_postgres_database"
};

-- Verify connection by querying the robot_telemetry table:
SELECT * FROM robot_postgres_db.robot_telemetry
ORDER BY timestamp DESC
LIMIT 10;

-- Check database statistics:
SELECT
    COUNT(*) as total_records,
    MIN(timestamp) as first_reading,
    MAX(timestamp) as last_reading,
    AVG(battery_level) as avg_battery,
    AVG(temperature_celsius) as avg_temperature
FROM robot_postgres_db.robot_telemetry;

---------------------
-- STEP 2: CREATE ANOMALY DETECTION VIEW
---------------------
-- Create a view that filters for anomalous robot readings
-- Anomalies are defined as:
--   * Battery level < 20% (low battery warning)
--   * Temperature > 80°C (high temperature warning)

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

-- Preview the anomalies:
SELECT * FROM anomalous_robots LIMIT 10;

---------------------
-- STEP 3: CREATE GEMINI AI MODEL
---------------------
-- Create an AI model using Google Gemini for generating maintenance reports
-- This model will analyze robot telemetry and provide human-readable insights

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

-- Wait for model to be created (this may take a moment)
-- Check model status:
SELECT * FROM models WHERE name = 'gemini_robot_reporter';

---------------------
-- STEP 4: GENERATE AI REPORTS FOR ANOMALIES
---------------------
-- Query that joins anomalous readings with the Gemini AI model
-- to generate natural language maintenance reports

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
LIMIT 5;

---------------------
-- STEP 5: CREATE ENRICHED ANOMALY TABLE
---------------------
-- Store AI-generated reports in a persistent table for historical analysis

CREATE TABLE files.robot_anomaly_reports (
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
);

-- View the stored reports:
SELECT * FROM files.robot_anomaly_reports
ORDER BY timestamp DESC
LIMIT 10;

---------------------
-- STEP 6: USEFUL QUERIES
---------------------

-- Get AI report for most recent anomaly:
SELECT
    robot_id,
    timestamp,
    battery_level,
    temperature_celsius,
    severity,
    g.report
FROM anomalous_robots AS a
JOIN gemini_robot_reporter AS g
ORDER BY timestamp DESC
LIMIT 1;

-- Count anomalies by type:
SELECT
    issue_type,
    severity,
    COUNT(*) as count
FROM anomalous_robots
GROUP BY issue_type, severity
ORDER BY count DESC;

-- Get all critical issues with AI analysis:
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

-- Real-time monitoring query (run this periodically):
SELECT
    COUNT(*) as active_anomalies,
    SUM(CASE WHEN severity = 'CRITICAL' THEN 1 ELSE 0 END) as critical_count,
    SUM(CASE WHEN severity = 'WARNING' THEN 1 ELSE 0 END) as warning_count
FROM anomalous_robots
WHERE timestamp > NOW() - INTERVAL 1 HOUR;

---------------------
-- STEP 7: CREATE CHATBOT AGENT (OPTIONAL)
---------------------
-- Create an intelligent agent that can answer questions about your robot fleet

CREATE AGENT robot_monitor_agent
USING
    model = 'gemini_robot_reporter',
    data = {
        "tables": ['robot_postgres_db.robot_telemetry', 'anomalous_robots']
    };

-- Example questions to ask the agent:
SELECT answer FROM robot_monitor_agent
WHERE question = 'What is the current status of ROBOT-001?';

SELECT answer FROM robot_monitor_agent
WHERE question = 'How many anomalies occurred in the last hour?';

SELECT answer FROM robot_monitor_agent
WHERE question = 'What are the most common types of failures?';

SELECT answer FROM robot_monitor_agent
WHERE question = 'Should we schedule maintenance for ROBOT-001?';

-- ============================================================================
-- NOTES:
-- ============================================================================
-- * The Gemini model requires an API key to be configured in MindsDB Settings
-- * AI report generation may take 2-3 seconds per anomaly 
-- * The anomalous_robots view automatically filters for battery < 20% or temp > 80°C
-- * You can modify the prompt_template to customize the AI report format
-- * Use the robot_monitor_agent for natural language queries
-- ============================================================================
-- ============================================================================
-- CREATE ROBOT MONITORING AGENT
-- ============================================================================
-- This agent can answer natural language questions about robot telemetry data
-- and anomalies using Google Gemini AI.
--
-- Prerequisites:
--   1. robot_postgres_db connection created (from mindsdb_setup.sql)
--   2. anomalous_robots view created
--   3. Gemini API key configured in MindsDB Settings
-- ============================================================================

---------------------
-- CREATE THE AGENT
---------------------
-- This agent has access to:
--   * robot_postgres_db.robot_telemetry - All telemetry data
--   * anomalous_robots - Filtered view of anomalies only

CREATE AGENT robot_monitor_agent
USING
    data = {
        "tables": [
            "robot_postgres_db.robot_telemetry",
            "anomalous_robots"
        ]
    };

-- Verify agent was created successfully:
SHOW AGENTS;
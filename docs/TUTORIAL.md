# Smart Robot Monitor - Step-by-Step Tutorial

This tutorial will guide you through building an AI-powered robot monitoring system using Vultr, MindsDB, and Gemini API.

## Prerequisites

Before starting, ensure you have:
- [ ] Vultr account with billing enabled
- [ ] Google AI Studio account (for Gemini API key)
- [ ] Basic knowledge of SQL and Python
- [ ] SSH client installed
- [ ] Python 3.8+ on your local machine

## Estimated Time

Total: 9-14 hours (can be spread over 2-3 days)

---

## Part 1: Infrastructure Setup

See `../config/vultr_setup.md` for detailed Vultr instance setup instructions.

**Summary**:
1. Deploy Ubuntu 22.04 instance on Vultr
2. Install PostgreSQL
3. Install MindsDB (via Docker)
4. Configure firewall
5. Verify all services are running

**Checkpoint**: You should be able to access PostgreSQL and MindsDB from your local machine.

---

## Part 2: Database Setup

### Step 1: Create the Schema

```bash
# Copy the schema file to your Vultr instance
scp database/schemas/robot_telemetry.sql root@your-vultr-ip:~/

# SSH into Vultr
ssh root@your-vultr-ip

# Create the table
psql -U robot_user -d robot_monitor_db -f robot_telemetry.sql
```

### Step 2: Verify

```sql
psql -U robot_user -d robot_monitor_db

\dt  -- List tables
\d robot_telemetry  -- Describe table structure
```

**Checkpoint**: The `robot_telemetry` table exists with correct columns.

---

## Part 3: Robot Simulator

### Step 1: Set Up Local Environment

```bash
# Clone or navigate to project directory
cd vultr-mindsdb-gemini

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your credentials
vim .env
```

### Step 3: Run the Simulator

```bash
cd simulator
python robot_simulator.py
```

**Expected Output**:
```
[2025-01-15 10:23:45] ROBOT-001: Battery=98.5%, Temp=62.3°C, Status=0 ✓
[2025-01-15 10:23:50] ROBOT-001: Battery=96.2%, Temp=65.1°C, Status=0 ✓
```

**Checkpoint**: Data is being inserted into PostgreSQL. Verify with:
```sql
SELECT * FROM robot_telemetry ORDER BY timestamp DESC LIMIT 10;
```

---

## Part 4: MindsDB Integration

### Step 1: Access MindsDB

Open web browser: `http://your-vultr-ip:47334`

### Step 2: Connect to PostgreSQL

Run this in MindsDB SQL editor:

```sql
CREATE DATABASE postgresql_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "localhost",
    "port": 5432,
    "database": "robot_monitor_db",
    "user": "robot_user",
    "password": "your_password"
};
```

### Step 3: Test Connection

```sql
SELECT * FROM postgresql_db.robot_telemetry LIMIT 5;
```

**Checkpoint**: MindsDB can query your PostgreSQL data.

---

## Part 5: Anomaly Detection

### Step 1: Create Anomaly View

```sql
CREATE VIEW anomalous_robots AS
SELECT * FROM postgresql_db.robot_telemetry
WHERE battery_level < 20 OR temperature_celsius > 80
ORDER BY timestamp DESC;
```

### Step 2: Test the View

```sql
SELECT * FROM anomalous_robots;
```

Initially, this might be empty. Let your simulator run until anomalies occur.

**Checkpoint**: The view returns rows when anomalies exist.

---

## Part 6: Gemini Integration

### Step 1: Get Gemini API Key

1. Go to https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy the key

### Step 2: Create Gemini Model in MindsDB

```sql
CREATE MODEL gemini_robot_reporter
PREDICT report
USING
    engine = 'gemini',
    api_key = 'YOUR_GEMINI_API_KEY_HERE',
    model_name = 'gemini-pro',
    prompt_template = 'You are a robot maintenance expert. A robot named {{robot_id}} has triggered an alert. Current status: Battery level is {{battery_level}}%, Temperature is {{temperature_celsius}}°C, recorded at {{timestamp}}. Provide: 1) Severity assessment (Low/Medium/High), 2) Specific maintenance steps, 3) Recommended action (CONTINUE/RETURN_TO_BASE/EMERGENCY_STOP). Format your response clearly.';
```

### Step 3: Test Gemini Model

```sql
SELECT report
FROM gemini_robot_reporter
WHERE robot_id = 'ROBOT-001'
AND battery_level = 15
AND temperature_celsius = 85;
```

**Checkpoint**: Gemini returns a formatted maintenance report.

---

## Part 7: The Complete Alert System

### Final Query

```sql
SELECT
    r.robot_id,
    r.battery_level,
    r.temperature_celsius,
    r.timestamp,
    g.report
FROM anomalous_robots AS r
JOIN gemini_robot_reporter AS g;
```

**Expected Output**:
| robot_id | battery_level | temperature_celsius | timestamp | report |
|----------|---------------|---------------------|-----------|--------|
| ROBOT-001 | 18.5 | 45.2 | 2025-01-15... | Severity: High. Battery critically low... |

---

## Part 8: Testing

### Scenario 1: Low Battery

1. Wait for simulator to drain battery below 20%
2. Run the final query
3. Verify Gemini suggests "RETURN_TO_BASE"

### Scenario 2: High Temperature

1. Trigger temperature spike in simulator (edit code if needed)
2. Run the final query
3. Verify Gemini identifies overheating issue

### Scenario 3: Multiple Anomalies

1. Create scenario with both low battery AND high temp
2. Verify Gemini prioritizes correctly

---

## Troubleshooting

See `TROUBLESHOOTING.md` for common issues and solutions.

---

## Next Steps

- Add multiple robots (modify simulator)
- Create automated monitoring script
- Build a simple dashboard
- Set up email/Slack notifications

Congratulations! You've built an AI-powered robot monitoring system! 🎉

# Robot Monitor Agent - Usage Guide

The Robot Monitor Agent is an AI-powered assistant that can answer natural language questions about your robot fleet using Google Gemini.

## Quick Start

### Create the Agent

```sql
CREATE AGENT robot_monitor_agent
USING
    model = 'gemini-pro',
    data = {
        "tables": [
            "robot_postgres_db.robot_telemetry",
            "anomalous_robots"
        ]
    };
```

### Ask Questions

```sql
SELECT answer FROM robot_monitor_agent
WHERE question = 'What is the current status of ROBOT-001?';
```

## What Can the Agent Do?

The agent can:
- ✅ Query and analyze robot telemetry data
- ✅ Identify patterns and trends
- ✅ Provide maintenance recommendations
- ✅ Answer questions about anomalies
- ✅ Compare data across time periods
- ✅ Generate health reports
- ✅ Explain issues in natural language

## Example Questions

### Current Status

```sql
-- Get robot status
SELECT answer FROM robot_monitor_agent
WHERE question = 'What is the current status of ROBOT-001?';

-- Health check
SELECT answer FROM robot_monitor_agent
WHERE question = 'Is ROBOT-001 healthy? Should I be concerned?';
```

### Anomaly Analysis

```sql
-- Count anomalies
SELECT answer FROM robot_monitor_agent
WHERE question = 'How many anomalies have occurred?';

-- Recent issues
SELECT answer FROM robot_monitor_agent
WHERE question = 'What anomalies occurred today?';

-- Critical alerts
SELECT answer FROM robot_monitor_agent
WHERE question = 'Show me all critical alerts with status_code = 2';
```

### Battery Analysis

```sql
-- Battery trends
SELECT answer FROM robot_monitor_agent
WHERE question = 'What is the average battery level?';

-- Low battery events
SELECT answer FROM robot_monitor_agent
WHERE question = 'When was the last low battery warning?';

-- Battery prediction
SELECT answer FROM robot_monitor_agent
WHERE question = 'Based on the drain rate, when will the battery reach 20%?';
```

### Temperature Analysis

```sql
-- Temperature patterns
SELECT answer FROM robot_monitor_agent
WHERE question = 'What are the temperature trends?';

-- High temperature events
SELECT answer FROM robot_monitor_agent
WHERE question = 'When did temperature exceed 80°C?';

-- Temperature correlation
SELECT answer FROM robot_monitor_agent
WHERE question = 'Is there a correlation between battery level and temperature?';
```

### Maintenance Recommendations

```sql
-- Maintenance schedule
SELECT answer FROM robot_monitor_agent
WHERE question = 'Should we schedule maintenance for ROBOT-001?';

-- Comprehensive report
SELECT answer FROM robot_monitor_agent
WHERE question = 'Provide a comprehensive health report for ROBOT-001';

-- Risk assessment
SELECT answer FROM robot_monitor_agent
WHERE question = 'What are the biggest risks to robot operations right now?';
```

### Data Insights

```sql
-- Compare time periods
SELECT answer FROM robot_monitor_agent
WHERE question = 'Compare performance in the first 10 readings vs last 10 readings';

-- Failure patterns
SELECT answer FROM robot_monitor_agent
WHERE question = 'What are the most common types of failures?';

-- Operational efficiency
SELECT answer FROM robot_monitor_agent
WHERE question = 'What percentage of time is the robot operating normally?';
```

## Advanced Usage

### Custom System Prompt

Create a specialized agent with custom personality:

```sql
CREATE AGENT robot_maintenance_assistant
USING
    model = 'gemini-pro',
    data = {
        "tables": [
            "robot_postgres_db.robot_telemetry",
            "anomalous_robots"
        ]
    },
    system_prompt = '
You are an expert robot maintenance engineer.
Provide concise, actionable recommendations.
Highlight urgent issues with clear severity ratings.
Always support recommendations with data.
';
```

### Multi-Step Analysis

The agent can handle complex, multi-part questions:

```sql
SELECT answer FROM robot_monitor_agent
WHERE question = '
Analyze ROBOT-001 performance:
1. What is the overall health status?
2. Are there any concerning trends?
3. What maintenance actions do you recommend?
4. What is the urgency level?
';
```

## Using the Web Interface

### MindsDB Respond Interface

1. Open MindsDB web interface
2. Click on **"Respond"** tab
3. Select **"robot_monitor_agent"** from dropdown
4. Type your question and press Enter
5. Have a conversation with the agent

Example conversation:
```
You: What's the status of ROBOT-001?
Agent: ROBOT-001 has experienced 4 anomalies...

You: Should I schedule maintenance?
Agent: Based on the data, I recommend...

You: When was the last critical alert?
Agent: The most recent critical alert occurred at...
```

## Best Practices

### ✅ Do's

- **Be specific**: "What was the battery level at 2pm?" is better than "What was the battery?"
- **Ask follow-up questions**: The agent maintains context
- **Request data-backed answers**: "Show me the data supporting your recommendation"
- **Use natural language**: Write questions as you would ask a human expert

### ❌ Don'ts

- **Don't ask vague questions**: "Is everything okay?" → Instead: "Are there any active anomalies?"
- **Don't assume real-time**: Agent queries the database, not live sensors
- **Don't ask for predictions beyond data**: Agent analyzes existing data, not future events (unless based on trends)

## Performance Tips

### Response Time

- Simple queries: 2-3 seconds
- Complex analysis: 5-10 seconds
- Multi-table joins: 10-15 seconds

### Rate Limits

Gemini API free tier:
- 60 requests per minute
- 1,500 requests per day

For production, consider:
- Caching common queries
- Batching similar questions
- Using a paid API tier

## Troubleshooting

### Agent Not Responding

**Check agent exists:**
```sql
SHOW AGENTS;
```

**Verify model is configured:**
```sql
SELECT * FROM models WHERE name = 'gemini-pro';
```

**Check API key:**
Go to Settings → Models → Verify Gemini API key is valid

### Slow Responses

- Gemini API calls take 2-5 seconds per query
- Complex questions with multiple table joins take longer
- This is normal behavior

### Inaccurate Answers

- Make questions more specific
- Verify the agent has access to correct tables
- Check if data exists in the database
- Try rephrasing the question

### "No Data Found" Errors

**Verify tables are accessible:**
```sql
SELECT * FROM robot_postgres_db.robot_telemetry LIMIT 1;
SELECT * FROM anomalous_robots LIMIT 1;
```

**Recreate agent if needed:**
```sql
DROP AGENT robot_monitor_agent;
-- Then recreate using CREATE AGENT
```

## Agent Management

### View All Agents
```sql
SHOW AGENTS;
```

### Describe Agent
```sql
DESCRIBE robot_monitor_agent;
```

### Update Agent

To update, drop and recreate:
```sql
DROP AGENT robot_monitor_agent;

CREATE AGENT robot_monitor_agent
USING
    model = 'gemini-pro',
    data = { ... };
```

### Delete Agent
```sql
DROP AGENT robot_monitor_agent;
```

## Next Steps

1. ✅ Create the agent using `create_agent.sql`
2. ✅ Test with example questions
3. ✅ Explore the web interface for chat-style interaction
4. ✅ Customize the system prompt for your use case
5. ✅ Build a dashboard or application that uses the agent

## Resources

- Full SQL script: `create_agent.sql`
- MindsDB Setup: `docs/MINDSDB_SETUP.md`
- Architecture: `docs/ARCHITECTURE.md`
- Main README: `README.md`

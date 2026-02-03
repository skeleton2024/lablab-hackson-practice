# Architecture Documentation

Detailed architecture and design decisions for the Smart Robot Monitor project.

---

## System Overview

The Smart Robot Monitor is a distributed system that demonstrates real-time data processing, AI integration, and cloud infrastructure management. It simulates a robotic monitoring system that uses AI to generate human-readable maintenance reports.

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      LOCAL MACHINE                           │
│                                                              │
│  ┌────────────────────────────────────────────┐             │
│  │      Robot Simulator (Python)              │             │
│  │  • Generates telemetry every 5s            │             │
│  │  • Simulates battery drain                 │             │
│  │  • Injects anomalies randomly               │             │
│  └──────────────┬─────────────────────────────┘             │
│                 │ psycopg2                                   │
└─────────────────┼────────────────────────────────────────────┘
                  │ TCP/IP (Port 5432)
                  ▼
┌──────────────────────────────────────────────────────────────┐
│                    VULTR CLOUD INSTANCE                      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              PostgreSQL Database                       │  │
│  │  • Stores time-series telemetry data                  │  │
│  │  • Primary key: (timestamp, robot_id)                 │  │
│  │  • Indexes for efficient querying                     │  │
│  └───────────────┬────────────────────────────────────────┘  │
│                  │ localhost                                 │
│                  ▼                                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   MindsDB                              │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Database Connector (PostgreSQL)                 │  │  │
│  │  │  • Reads from robot_telemetry table              │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Anomaly Detection (SQL View)                    │  │  │
│  │  │  • battery_level < 20                            │  │  │
│  │  │  • temperature_celsius > 80                      │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Gemini Model Integration                        │  │  │
│  │  │  • Connects to Gemini API                        │  │  │
│  │  │  • Executes prompt template                      │  │  │
│  │  │  • Returns natural language report               │  │  │
│  │  └──────────────┬───────────────────────────────────┘  │  │
│  └─────────────────┼────────────────────────────────────────┘  │
└────────────────────┼───────────────────────────────────────────┘
                     │ HTTPS
                     ▼
          ┌──────────────────────────┐
          │    Google Gemini API     │
          │  • Gemini Pro Model      │
          │  • NL Generation         │
          └──────────────────────────┘
```

---

## Component Details

### 1. Robot Simulator (Python)

**Purpose**: Generates realistic robot telemetry data for testing and demonstration.

**Technology**: Python 3.8+, psycopg2, python-dotenv

**Key Features**:
- Simulates gradual battery drain (100% → 0%)
- Temperature fluctuation with normal distribution
- Configurable anomaly injection
- Parameterized data generation rate

**Data Flow**:
```python
1. Generate telemetry data
2. Apply anomaly logic (if triggered)
3. Insert into PostgreSQL via psycopg2
4. Sleep for configured interval
5. Repeat
```

**Design Decisions**:
- **Why Python?** Rapid prototyping, excellent DB libraries
- **Why not real robots?** Tutorial simplicity, reproducibility
- **Why anomaly injection?** Guarantees interesting test scenarios

---

### 2. PostgreSQL Database

**Purpose**: Persistent storage for time-series telemetry data.

**Technology**: PostgreSQL 14+

**Schema Design**:
```sql
CREATE TABLE robot_telemetry (
    timestamp TIMESTAMPTZ NOT NULL,      -- When data was recorded
    robot_id VARCHAR(50) NOT NULL,       -- Robot identifier
    battery_level FLOAT NOT NULL,        -- 0-100%
    temperature_celsius FLOAT NOT NULL,  -- Degrees Celsius
    status_code INT,                     -- 0=OK, 1=Warn, 2=Error
    PRIMARY KEY (timestamp, robot_id)
);

CREATE INDEX idx_timestamp ON robot_telemetry(timestamp);
CREATE INDEX idx_robot_id ON robot_telemetry(robot_id);
```

**Design Decisions**:
- **Primary Key Choice**: Composite key (timestamp, robot_id) ensures uniqueness and efficient time-based queries
- **TIMESTAMPTZ**: Stores timezone-aware timestamps for global deployments
- **Float vs Decimal**: Float is sufficient for sensor readings; decimal not needed
- **Indexes**: Support common query patterns (time-range, per-robot filtering)

**Scaling Considerations**:
- Time-series data grows indefinitely → implement data retention policy
- Partitioning by date for large datasets
- TimescaleDB extension for advanced time-series features

---

### 3. MindsDB

**Purpose**: Integration layer connecting PostgreSQL with AI services.

**Technology**: MindsDB (Docker container)

**Key Functions**:

1. **Database Connector**:
   - Reads from PostgreSQL
   - Provides unified SQL interface
   - Handles connection pooling

2. **Anomaly Detection View**:
   ```sql
   CREATE VIEW anomalous_robots AS
   SELECT * FROM postgresql_db.robot_telemetry
   WHERE battery_level < 20 OR temperature_celsius > 80;
   ```
   - Simple threshold-based detection
   - Real-time filtering
   - No ML training required

3. **Gemini Model Integration**:
   ```sql
   CREATE MODEL gemini_robot_reporter
   PREDICT report
   USING engine = 'gemini', ...
   ```
   - Abstracts API calls as SQL model
   - Handles prompt templating
   - Manages API credentials

**Design Decisions**:
- **Why MindsDB?** Simplifies AI integration via SQL
- **Why Docker?** Consistent deployment, easy updates
- **Why threshold detection?** Tutorial simplicity; ML anomaly detection adds complexity

**Alternative Approaches Considered**:
- ❌ Direct Python script querying PostgreSQL + Gemini → More code, less elegant
- ❌ MindsDB's built-in ML anomaly detection → Requires training data, longer tutorial
- ✅ **Chosen approach**: Balance of simplicity and feature demonstration

---

### 4. Gemini API

**Purpose**: Natural language generation for maintenance reports.

**Technology**: Google Gemini Pro (via REST API)

**Prompt Engineering**:
```
You are a robot maintenance expert.
A robot named {{robot_id}} has triggered an alert.
Current status:
- Battery level: {{battery_level}}%
- Temperature: {{temperature_celsius}}°C
- Timestamp: {{timestamp}}

Provide:
1) Severity assessment (Low/Medium/High)
2) Specific maintenance steps
3) Recommended action (CONTINUE/RETURN_TO_BASE/EMERGENCY_STOP)
```

**Design Decisions**:
- **Gemini vs GPT**: Gemini chosen for Google AI Studio integration, free tier
- **Prompt structure**: Structured output ensures consistent responses
- **Context window**: Current data only (no historical context) for simplicity

**Token Usage**:
- Input: ~100 tokens per query
- Output: ~150 tokens per response
- Cost: Minimal on free tier

---

## Data Flow

### End-to-End Flow

```
1. Simulator generates data
   ↓
2. INSERT INTO PostgreSQL
   ↓
3. MindsDB queries PostgreSQL
   ↓
4. anomalous_robots view filters thresholds
   ↓
5. JOIN with gemini_robot_reporter model
   ↓
6. MindsDB sends prompt to Gemini API
   ↓
7. Gemini returns natural language report
   ↓
8. MindsDB returns SQL result with report
```

### Query Execution

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

**Execution Plan**:
1. MindsDB executes `anomalous_robots` view on PostgreSQL
2. For each row, MindsDB calls Gemini model:
   - Substitutes template variables
   - Sends HTTP request to Gemini API
   - Parses response
3. Returns combined result set

**Performance Characteristics**:
- **Latency**: ~2-3 seconds per anomaly (Gemini API call)
- **Throughput**: Limited by Gemini rate limits (60 RPM on free tier)
- **Caching**: MindsDB doesn't cache LLM responses (always fresh)

---

## Security Considerations

### Implemented

1. **Database**:
   - User authentication required
   - Password-based access
   - Limited privileges for robot_user

2. **API Keys**:
   - Gemini API key stored in MindsDB (not in code)
   - .env files excluded from git

3. **Network**:
   - Firewall configured (UFW)
   - Only necessary ports exposed

### Future Enhancements

- [ ] SSL/TLS for PostgreSQL connections
- [ ] MindsDB authentication enabled
- [ ] API key rotation
- [ ] Secrets management (Vault, AWS Secrets Manager)
- [ ] Network segmentation

---

## Scalability Analysis

### Current Limitations

| Component | Bottleneck | Max Throughput |
|-----------|------------|----------------|
| Simulator | Single-threaded | ~1 insert/sec |
| PostgreSQL | Disk I/O | ~1000 inserts/sec |
| MindsDB | Gemini API rate limit | 60 queries/min |
| Gemini API | Free tier quota | 60 RPM |

### Scaling Strategies

**Horizontal Scaling**:
- Multiple simulators → Multiple robots
- PostgreSQL read replicas → Distribute queries
- MindsDB cluster → Not supported in open-source

**Vertical Scaling**:
- Larger Vultr instance → More RAM/CPU for PostgreSQL
- Paid Gemini tier → Higher rate limits

**Optimization**:
- Batch anomaly queries → Reduce API calls
- Cache recent Gemini responses → Avoid duplicate calls
- Data retention policy → Limit database growth

---

## Technology Alternatives

### Why These Technologies?

| Technology | Alternatives Considered | Reason for Choice |
|------------|-------------------------|-------------------|
| Vultr | AWS, DigitalOcean, GCP | Tutorial focus, simpler UI |
| PostgreSQL | MySQL, MongoDB | Industry standard, time-series support |
| MindsDB | LangChain, direct API | SQL abstraction, tutorial novelty |
| Gemini | GPT-4, Claude | Free tier, Google ecosystem |
| Python | Node.js, Go | Rapid prototyping, psycopg2 |

### When to Use Different Stack

**Use AWS instead** if:
- You need enterprise features (IAM, VPC)
- You're already in AWS ecosystem
- You need global deployment

**Use GPT-4 instead** if:
- You need more advanced reasoning
- You have OpenAI credits
- You need function calling

**Skip MindsDB if**:
- You prefer direct API integration
- You need more control over caching
- Tutorial length is not a concern

---

## Lessons Learned

### What Worked Well

✅ Threshold-based detection (simple, predictable)
✅ MindsDB's SQL abstraction (elegant integration)
✅ Docker for MindsDB (easy deployment)
✅ Simulator approach (reproducible scenarios)

### What Could Be Improved

⚠️ Real-time alerting (currently manual queries)
⚠️ Historical context in Gemini prompts (only current state)
⚠️ Error handling in simulator (fails on DB disconnect)
⚠️ Monitoring/logging (minimal observability)

---

## Future Enhancements

1. **Multi-Robot Fleet**: Extend simulator to handle N robots
2. **Web Dashboard**: Real-time visualization (React + WebSocket)
3. **Automated Actions**: Execute Gemini's recommended actions
4. **Historical Analysis**: Use time-series ML for predictive maintenance
5. **Notification System**: Email/Slack alerts via webhooks
6. **Mobile App**: Monitor robots on-the-go

---

## Conclusion

This architecture demonstrates a modern approach to AI-powered monitoring systems:
- Cloud infrastructure (Vultr)
- Time-series data storage (PostgreSQL)
- AI integration via SQL (MindsDB)
- Natural language generation (Gemini)

The design prioritizes **tutorial simplicity** while maintaining **production-like patterns**. It's easily extensible for real-world use cases.

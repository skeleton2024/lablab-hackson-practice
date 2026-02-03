# Smart Robot Monitor with AI Alerts

A tutorial project demonstrating the integration of **Vultr**, **MindsDB**, and **Gemini API** to build an intelligent robot monitoring system that generates natural language maintenance reports.

## 🎯 Project Overview

This project simulates a robotic system that:
- Generates telemetry data (battery, temperature, status)
- Stores data in a PostgreSQL database on Vultr
- Uses MindsDB to detect anomalies via threshold rules
- Leverages Gemini AI to generate contextual maintenance reports and action recommendations

## 🏗️ Architecture

```
┌─────────────────┐
│ Robot Simulator │ (Python Script)
│  - Battery      │
│  - Temperature  │
│  - Status       │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         Vultr Cloud Instance            │
│  ┌──────────────────────────────────┐   │
│  │      PostgreSQL Database         │   │
│  │   (robot_telemetry table)        │   │
│  └──────────┬───────────────────────┘   │
│             │                            │
│  ┌──────────▼───────────────────────┐   │
│  │         MindsDB                  │   │
│  │  - Anomaly View (Thresholds)     │   │
│  │  - Gemini Model Integration      │   │
│  └──────────┬───────────────────────┘   │
└─────────────┼───────────────────────────┘
              │
              ▼
     ┌────────────────────┐
     │   Gemini API       │
     │ (NL Report Gen)    │
     └────────────────────┘
```

## 📁 Project Structure

```
vultr-mindsdb-gemini/
├── README.md                          # This file - project overview and plan
├── .env.example                       # Environment variables template
├── requirements.txt                   # Python dependencies
│
├── simulator/                         # Robot simulator component
│   ├── __init__.py
│   ├── robot_simulator.py            # Main simulator script
│   ├── config.py                     # Simulator configuration
│   └── README.md                     # Simulator documentation
│
├── database/                          # Database related files
│   ├── schemas/
│   │   └── robot_telemetry.sql      # Table schema definition
│   ├── migrations/
│   │   └── 001_initial_setup.sql    # Initial database setup
│   └── README.md                     # Database setup instructions
│
├── mindsdb/                           # MindsDB configurations
│   ├── queries/
│   │   ├── create_view.sql          # Anomaly detection view
│   │   ├── create_gemini_model.sql  # Gemini model setup
│   │   └── query_alerts.sql         # Query for getting AI reports
│   ├── models/
│   │   └── gemini_config.yaml       # Gemini model configuration
│   └── README.md                     # MindsDB setup instructions
│
├── scripts/                           # Utility scripts
│   ├── setup_database.sh             # Database initialization script
│   ├── test_connection.py            # Test database connectivity
│   └── run_simulator.sh              # Start the simulator
│
├── config/                            # Configuration files
│   └── vultr_setup.md                # Vultr instance setup guide
│
└── docs/                              # Documentation
    ├── TUTORIAL.md                    # Step-by-step tutorial
    ├── TROUBLESHOOTING.md             # Common issues and solutions
    └── ARCHITECTURE.md                # Detailed architecture explanation
```

## 🚀 Implementation Plan

### Phase 1: Infrastructure Setup (Vultr)

**Objective**: Deploy and configure a Vultr cloud instance with PostgreSQL and MindsDB

**Tasks**:
- [ ] 1.1 Create Vultr account and deploy a cloud compute instance
  - Recommended: Ubuntu 22.04 LTS
  - Minimum specs: 2 vCPU, 4GB RAM, 80GB SSD
  - Configure firewall rules (PostgreSQL: 5432, MindsDB: 47334)

- [ ] 1.2 Install PostgreSQL on Vultr instance
  - Install PostgreSQL 14+
  - Configure remote access
  - Create database: `robot_monitor_db`
  - Create user with appropriate privileges

- [ ] 1.3 Install MindsDB on Vultr instance
  - Install via Docker or pip
  - Configure MindsDB to connect to local PostgreSQL
  - Verify MindsDB web interface access

- [ ] 1.4 Secure the instance
  - Set up SSH key authentication
  - Configure firewall (UFW)
  - Set strong passwords

**Deliverables**:
- Running Vultr instance
- PostgreSQL accessible remotely
- MindsDB running and accessible
- Connection credentials documented

---

### Phase 2: Database Schema Design

**Objective**: Create the database schema for storing robot telemetry data

**Tasks**:
- [ ] 2.1 Design `robot_telemetry` table schema
  - timestamp (TIMESTAMPTZ)
  - robot_id (VARCHAR)
  - battery_level (FLOAT)
  - temperature_celsius (FLOAT)
  - status_code (INT)
  - Add appropriate indexes

- [ ] 2.2 Create migration scripts
  - Initial schema creation
  - Sample data insertion (optional)

- [ ] 2.3 Test database schema
  - Manual INSERT/SELECT queries
  - Verify data types and constraints

**Deliverables**:
- `robot_telemetry.sql` schema file
- Migration script
- Tested and working database table

---

### Phase 3: Robot Simulator Development

**Objective**: Build a Python script that simulates robot telemetry data

**Tasks**:
- [ ] 3.1 Set up Python environment
  - Create virtual environment
  - Install dependencies (psycopg2, python-dotenv)
  - Create requirements.txt

- [ ] 3.2 Develop simulator core logic
  - Generate realistic battery drain (100% → 0%)
  - Simulate temperature fluctuations (normal: 40-70°C)
  - Create anomaly injection logic (temp spikes, low battery)
  - Add configurable intervals (default: 5 seconds)

- [ ] 3.3 Implement database connection
  - Read connection string from environment variables
  - Insert telemetry data into PostgreSQL
  - Error handling and retry logic

- [ ] 3.4 Add configuration options
  - Robot ID
  - Anomaly probability
  - Data generation rate
  - Threshold values

**Deliverables**:
- Working `robot_simulator.py`
- Configuration file
- requirements.txt
- Documentation on running the simulator

---

### Phase 4: MindsDB Integration

**Objective**: Set up MindsDB to detect anomalies and integrate with Gemini API

**Tasks**:
- [ ] 4.1 Connect MindsDB to PostgreSQL
  - Create database connection in MindsDB
  - Test query access to `robot_telemetry` table

- [ ] 4.2 Create anomaly detection view
  ```sql
  CREATE VIEW anomalous_robots AS
  SELECT * FROM postgresql_db.robot_telemetry
  WHERE battery_level < 20 OR temperature_celsius > 80;
  ```

- [ ] 4.3 Set up Gemini API credentials
  - Obtain Gemini API key from Google AI Studio
  - Configure API key in MindsDB

- [ ] 4.4 Create Gemini model in MindsDB
  ```sql
  CREATE MODEL gemini_robot_reporter
  PREDICT report
  USING
    engine = 'gemini',
    api_key = 'your_api_key',
    prompt_template = 'A robot named {{robot_id}} has an alert...';
  ```

- [ ] 4.5 Test the integration
  - Verify anomaly view returns correct data
  - Test Gemini model response generation

**Deliverables**:
- MindsDB connected to PostgreSQL
- Anomaly detection view created
- Gemini model configured and tested
- SQL query files documented

---

### Phase 5: AI-Powered Alert System

**Objective**: Query MindsDB to generate AI-powered maintenance reports

**Tasks**:
- [ ] 5.1 Create the main query that joins anomalies with Gemini
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

- [ ] 5.2 Refine Gemini prompt template
  - Include context: battery level, temperature, timestamp
  - Request structured output (severity, steps, action)
  - Test with various anomaly scenarios

- [ ] 5.3 Create monitoring script (optional)
  - Python script that periodically runs the query
  - Displays alerts in real-time
  - Logs reports to file

**Deliverables**:
- Working query that generates AI reports
- Refined prompt template
- Optional monitoring dashboard/script

---

### Phase 6: Testing & Validation

**Objective**: Ensure the entire system works end-to-end

**Tasks**:
- [ ] 6.1 End-to-end testing
  - Start simulator with normal data
  - Verify data appears in PostgreSQL
  - Trigger anomalies (low battery, high temp)
  - Verify MindsDB detects anomalies
  - Confirm Gemini generates appropriate reports

- [ ] 6.2 Edge case testing
  - No anomalies present
  - Multiple simultaneous anomalies
  - Rapid anomaly generation
  - Database connection failures

- [ ] 6.3 Performance testing
  - Simulate high-frequency data (1 record/second)
  - Test MindsDB query response time
  - Monitor resource usage on Vultr instance

**Deliverables**:
- Test results documentation
- Performance benchmarks
- Bug fixes for identified issues

---

### Phase 7: Documentation & Tutorial

**Objective**: Create comprehensive documentation for users to follow

**Tasks**:
- [ ] 7.1 Write step-by-step tutorial (TUTORIAL.md)
  - Prerequisites and requirements
  - Detailed setup instructions for each phase
  - Screenshots and code examples
  - Expected outputs at each step

- [ ] 7.2 Create troubleshooting guide
  - Common connection issues
  - MindsDB configuration problems
  - Gemini API errors
  - Solutions and workarounds

- [ ] 7.3 Document architecture decisions
  - Why these specific technologies
  - Alternative approaches considered
  - Scalability considerations

- [ ] 7.4 Add code comments and docstrings
  - Python code documentation
  - SQL query explanations
  - Configuration file comments

**Deliverables**:
- Complete TUTORIAL.md
- TROUBLESHOOTING.md
- ARCHITECTURE.md
- Well-commented code

---

### Phase 8: Polish & Extras (Optional Enhancements)

**Objective**: Add nice-to-have features and improvements

**Tasks**:
- [ ] 8.1 Create a simple web dashboard
  - Display current robot status
  - Show recent alerts
  - Visualize telemetry trends

- [ ] 8.2 Add email/Slack notifications
  - Send alerts when anomalies detected
  - Integrate with notification services

- [ ] 8.3 Multiple robot support
  - Extend simulator to handle fleet of robots
  - Update queries for fleet monitoring

- [ ] 8.4 Historical analysis
  - Query for trends over time
  - Generate weekly summaries with Gemini

**Deliverables**:
- Enhanced features (as time permits)
- Additional documentation

---

## 🛠️ Technology Stack

- **Vultr**: Cloud infrastructure hosting
- **PostgreSQL**: Time-series telemetry data storage
- **MindsDB**: ML/AI integration layer and query orchestration
- **Gemini API**: Natural language report generation
- **Python**: Robot simulator and utility scripts

## 📋 Prerequisites

- Vultr account with billing enabled
- Google AI Studio account (for Gemini API key)
- Basic knowledge of SQL, Python, and command line
- SSH client for server access

## ⏱️ Estimated Timeline

- **Infrastructure Setup**: 2-3 hours
- **Database & Simulator**: 2-3 hours
- **MindsDB Integration**: 2-4 hours
- **Testing & Documentation**: 3-4 hours
- **Total**: 9-14 hours (spread over 2-3 days)

## 🎓 Learning Outcomes

By completing this project, you will learn:
- How to deploy and configure cloud infrastructure on Vultr
- PostgreSQL database design and management
- MindsDB's approach to AI/ML integration via SQL
- Gemini API for natural language generation
- Building end-to-end data pipelines
- System monitoring and alerting patterns

## 📝 License

MIT License - Feel free to use this tutorial for educational purposes.

## 🤝 Contributing

This is a tutorial project. Suggestions and improvements are welcome via issues or pull requests.

---

**Next Step**: Begin with Phase 1 - Infrastructure Setup. See `config/vultr_setup.md` for detailed instructions.

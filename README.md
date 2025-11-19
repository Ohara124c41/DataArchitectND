# Data Architect Nanodegree Portfolio

Hands-on deliverables from Udacity's Data Architect Nanodegree. Each sub-project tackles a different enterprise scenario—from governance and MDM foundations through dimensional modeling and large-scale data lake design. Everything is organized per project folder so you can review artifacts, diagrams, and SQL/scripts independently.

## Projects Overview

### 1. SneakerPark Data Governance (`data_governance`)
- **Goal:** Stand up Phase 1 of SneakerPark's enterprise data management program: catalog critical data assets, fix quality issues, and design an MDM solution across five microservices.
- **Highlights:** Enterprise conceptual data model, full data catalog (63 columns), data quality profiling with dashboard mockup, hybrid MDM architecture, matching rules, governance roles, and implementation-grade SQL scripts.
- **Technologies:** PostgreSQL, SQL, Mermaid (ERDs/architecture), HTML/CSS dashboard mockup, Excel/CSV templates.

### 2. Tech ABC Human Resources Database (`Design_an_HR_Database`)
- **Goal:** Replace a brittle spreadsheet-based HR tracker with a normalized, secure PostgreSQL schema that enforces historical accuracy and role-based access.
- **Highlights:** Comprehensive DDL (schema, tables, constraints, views), CRUD/verification scripts (q1–q7), optional extras (history function, naming enforcement), security model with least privilege + RLS patterns, staging/seed ETL guidance, ERD documentation.
- **Technologies:** PostgreSQL 9.5, SQL, psql automation, Mermaid/diagram exports.

### 3. Yelp + Weather Data Warehouse (`Design_a_Data_Warehouse`)
- **Goal:** Build an end-to-end Snowflake warehouse that blends Yelp business/review JSON with Las Vegas climate data to correlate ratings with weather conditions.
- **Highlights:** SnowSQL pipeline (`01`–`09`) covering staging, JSON flattening into ODS, review-weather integration, star-schema load (DIM/FACT), reporting query, compression metrics, and exportable diagrams/documentation.
- **Technologies:** Snowflake, SnowSQL CLI, SQL/VARIANT JSON functions, Mermaid diagrams, PDF report assets.

### 4. Medical Data Processing Enterprise Data Lake (`design_enterprise_data_lake`)
- **Goal:** Design an open-source enterprise data lake to replace a single-node SQL Server environment handling 77K daily files for 8K medical facilities.
- **Highlights:** Multi-layer architecture (ingestion, storage, processing, serving, security), detailed design doc (DOCX/PDF), executive presentation, Mermaid diagrams + PNG/SVG exports, dashboard mockups, starter requirements.
- **Technologies:** Apache NiFi, Kafka, HDFS/HBase, Spark, Flink, Hive, Presto, Druid, Superset, Ranger/Knox/Kerberos for security, Mermaid/diagramming tools.

## How to Work with the Repo

1. **Clone and enter the workspace**
   ```bash
   git clone https://github.com/ohara124c41/DataArchitectND.git
   cd DataArchitectND
   ```
2. **Pick a project folder** (`data_governance`, `Design_an_HR_Database`, `Design_a_Data_Warehouse`, or `design_enterprise_data_lake`). Each contains a dedicated `README` plus docs, diagrams, and scripts tied to that scenario.
3. **Follow project-specific instructions** for tooling setup (PostgreSQL, Snowflake/SnowSQL, Hadoop ecosystem tooling, etc.) and note that large datasets (e.g., Yelp JSON, climate CSVs) are intentionally excluded—acquire them per the project guidelines.
4. **Reuse the artifacts** (diagrams, SQL, docs, mockups) as references or starting points for similar data architecture engagements. Submit issues or notes per-project as needed via your usual Git workflow.

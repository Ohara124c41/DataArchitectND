# Medical Data Processing Enterprise Data Lake

Future-proof data platform design prepared for the *Medical Data Processing Company* engagement. The materials in this folder document how we replace the overloaded single-node SQL Server environment with an open-source, metadata-driven data lake that scales with the company's 20% YoY data growth.

## Project Snapshot
- **Scope:** Evaluate feasibility and design of a multi-layer enterprise data lake that handles 77K compressed files (15M records) per day from ~8K facilities.
- **Drivers:** Current nightly ETL + monolithic SQL Server stack cannot handle growth, introduces hours of downtime, and blocks ML/real-time analytics work.
- **Outcome:** Full architecture package (diagram, technical design, executive presentation, mockups) that proves how an open-source stack improves reliability, latency, and agility without vendor lock-in.

## Problem & Requirements Overview
### Pain Points We Address
- SQL Server is a single point of failure; a surge during nightly ETL recently crashed the environment for hours.
- Hundreds of bespoke SSIS scripts per source are brittle, slow to change, and duplicate similar transformation logic.
- Analytics teams must export copies of data nightly, creating silos, wasted storage, and stale insights.
- Backup/restore takes hours, leaving no rapid recovery path or tolerance for node failures.

### Business Goals
- Improve uptime, reporting latency, and customer experience across all medical facilities.
- Scale seamlessly with rising data volume/velocity while keeping historical data indefinitely.
- Accelerate innovation (dashboards, ML, CDC, ad-hoc SQL) from a single, centrally governed data estate.
- Leverage open-source technologies to reduce licensing cost and avoid vendor lock-in.

### Technical Capabilities (Non-Negotiable)
- Process files continuously rather than in nightly batches; support FTP/API/database sources.
- Separate data, metadata, and compute so each tier scales independently.
- Provide CDC/UPSERT support, schema evolution, and consistent metadata.
- Survive node failures without downtime; enforce strong security, lineage, and auditability.
- Serve multiple workloads (dashboards, reporting, ML, APIs) from the same curated datasets.

## Target Architecture Summary
High-level diagrams live in `diagrams/` (Mermaid sources) and `DataLakeSolutionArchitectureDiagram*.pdf`. The architecture follows a four-layer pattern with cross-cutting security/governance:

| Layer | Responsibilities | Selected Technologies |
| --- | --- | --- |
| **Ingestion** | Continuous collection of 77K files/day, schema validation, routing from FTP/API/DB sources. | Apache NiFi for flow management, Apache Kafka for streaming/CDC capture. |
| **Storage** | Durable, unlimited capacity lake that keeps raw + curated zones with metadata. | HDFS with 3x replication, HBase for low-latency record access, dedicated metadata/governance services for schema + lineage. |
| **Processing** | Batch + streaming transforms, SQL analytics, workflow orchestration replacing 70+ SSIS jobs. | Apache Spark (batch), Apache Flink (stream), Hive & Presto for SQL, Apache Airflow for metadata-driven orchestration. |
| **Serving** | Optimized marts for BI, dashboards, ML feature feeds, and clinical APIs. | Apache Druid for sub-second dashboards, Hive tables for historical warehouses, Apache Superset for visualization. |
| **Security & Governance (cross-layer)** | Centralized authentication/authorization, perimeter security, encryption, audit trails. | Kerberos, Apache Ranger, Apache Knox securing every tier. |

This design keeps raw and curated data in the lake, supports schema-on-read for agility, and reuses a single dataset across streaming analytics, SQL reporting, ML model training, and operational applications.

## Repository Layout
- `docs/`
  - `DataLakeArchitectureDesign.docx` & `../DataLakeArchitectureDesign.pdf`: formal 6+ page technical design detailing requirements, decisions, and rationales.
  - `DataLakeExecutivePresentation.pptx` & `../DataLakeExecutivePresentation.pdf`: business-facing pitch deck summarizing value, comparison vs. warehouse, and roadmap.
  - `ExecutivePresentationSlides-Complete.md`: Markdown source for the presentation narrative.
  - `company_profile.md`: Problem context, existing environment, and constraints.
  - `project_reference.md`: Full assignment brief, grading rubric, and checklist.
  - Supporting HTML exports (`DataLakeSolutionArchitecture-Simplified.html`, `DataLakeSolutionArchitectureDesign...`) for quick viewing without office apps.
- `diagrams/`
  - `sys_arch_high.mmd`, `MDM*.mmd`: Mermaid sources for the main system and master-data diagrams.
  - `.png`/`.svg` renderings ready for decks and documents.
- `mockup/mockup.pdf`: UX mockup of the proposed executive dashboard that consumes the serving layer.
- `starter/`: Original Udacity starter files and requirements for back-reference.

Root-level PDFs mirror the final deliverables so stakeholders can download/print without opening the `docs/` folder.

## Working With These Artifacts
- **Re-render Mermaid diagrams:** Edit the `.mmd` files and run `mmdc -i diagrams/sys_arch_high.mmd -o diagrams/sys_arch_high.png` (requires `@mermaid-js/mermaid-cli`). The HTML version in `docs/DataLakeSolutionArchitecture-Simplified.html` embeds the same definition for quick previews in a browser.
- **Update documents/deck:** Source versions reside in `docs/`. After editing, export to PDF (placing updated copies at the repo root) so reviewers without Office can read them.
- **Reference context quickly:** Use `docs/company_profile.md` for stakeholder/requirement refresh, and `docs/project_reference.md` for acceptance criteria before revising deliverables or creating new collateral.
- **Diagram assets in presentations:** The `diagrams/*.png` files already match the color palette used in the deck for copy/paste without re-formatting.

## Suggested Next Steps
1. Validate security/governance mappings (e.g., finalize metadata catalog tooling) and document integration points with existing IAM.
2. Prototype a NiFi + Kafka ingestion flow for one facility type to prove CDC throughput assumptions.
3. Stand up a small HDFS/Spark proof-of-concept to benchmark nightly workloads vs. current SQL Server timings.

With the above README, anyone opening the `design_enterprise_data_lake` folder can immediately understand the project intent, artefacts, and how to extend the work.

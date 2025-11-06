# Yelp Weather Data Warehouse

Designing a reporting data warehouse that blends Yelp business activity with local climate conditions using Snowflake.

## Project Overview

This project builds an end-to-end analytics pipeline:

1. Land six Yelp JSON extracts and two climate CSVs in Snowflake staging (`STG` schema).
2. Transform the semi-structured data into typed Operational Data Store tables (`ODS` schema).
3. Integrate reviews with daily weather using a shared date key.
4. Load a star-schema warehouse (`DWH` schema) and deliver a report that correlates ratings with weather.

All ETL steps are orchestrated with SnowSQL scripts in the `sql/` directory (`01_setup_env.sql` through `09_metrics.sql`). No vendor data is included in this repository; follow the download instructions below to obtain the public datasets.

## Repository Layout

```
README.md                 # Project guide and rubric alignment
docs/
  report.pdf              # Submission document (screenshots, diagrams, evidence)
sql/
  01_setup_env.sql        # Snowflake role/warehouse, database, schemas, and stages
  02_staging_tables.sql   # Creates raw staging tables for Yelp JSON and climate CSV
  03_copy_into_staging.sql# COPY commands to load six Yelp files + two climate files
  04_ods_build.sql        # Creates typed ODS tables
  05_json_xforms.sql      # Transforms staging → ODS using JSON functions and typed casts
  06_integrate_weather.sql# Builds REVIEW_WITH_WEATHER view (Yelp + climate integration)
  07_dwh_star.sql         # Loads DIM_DATE, DIM_BUSINESS, DIM_CUSTOMER, DIM_WEATHER, FACT_REVIEW
  08_report.sql           # Generates business/weather/ratings correlation report
  09_metrics.sql          # Row-count and storage metrics for STG and ODS
  11_cleanup_unused.sql   # Optional cleanup of deprecated helper tables/views
  12_reset_dwh.sql        # Resets DWH tables prior to re-running the star load
```

The numbered scripts (`01`–`09`) correspond to the rubric deliverables and should be run sequentially from SnowSQL. Helper scripts (`11`, `12`) assist with cleanup and reruns.

## Data Acquisition

You must download the datasets yourself; they are **not committed** to this repository.

1. **Yelp Open Dataset**  
   - Visit the [Yelp Dataset portal](https://business.yelp.com/data/resources/open-dataset/) and fill in the request form.  
   - Download the “JSON dataset” tarball (~4 GB compressed, ~8.7 GB uncompressed).  
   - Extract to obtain `business.json`, `review.json`, `user.json`, `tip.json`, `checkin.json`.  
   - Tip: On Windows, rename `yelp_dataset.tar` → `yelp_dataset.tgz` before extracting if your tool has issues.

2. **COVID-19 Yelp Features**  
   - Download `archive.zip` from [Kaggle: Yelp Academic Data Set – COVID Features](https://www.kaggle.com/claudiadodge/yelp-academic-data-set-covid-features?select=yelp_academic_dataset_covid_features.json).  
   - Extract the file `yelp_academic_dataset_covid_features.json`.

3. **Climate CSV files**  
   - Retrieve the Las Vegas weather CSVs from the Udacity classroom resources or directly from [Climate Explorer](https://crt-climate-explorer.nemac.org/):  
     - `USW00023169-LAS VEGAS MCCARRAN INTL AP-PRECIPITATION-INCH`  
     - `USW00023169-TEMPERATURE-DEGREEF`  
   - Rename to `precipitation.csv` and `temperature.csv` for consistency.

4. **Snowflake Setup**  
   - Create a free Snowflake account at [snowflake.com](https://www.snowflake.com/).  
   - Install the SnowSQL CLI using the [installation guide](https://docs.snowflake.com/en/user-guide/snowsql-install-config.html) or the direct [bootstrap repository](https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/index.html).  
   - Verify connectivity before running the scripts.

## Running the Pipeline

1. Open SnowSQL and authenticate to your Snowflake account.  
2. Execute each script in order:

   ```sql
   !source sql/01_setup_env.sql;
   !source sql/02_staging_tables.sql;
   !source sql/03_copy_into_staging.sql;
   !source sql/04_ods_build.sql;
   !source sql/05_json_xforms.sql;
   !source sql/06_integrate_weather.sql;
   !source sql/07_dwh_star.sql;
   !source sql/08_report.sql;
   !source sql/09_metrics.sql;
   ```

3. Capture the output at each step for documentation (row counts, SELECT results, etc.).
4. Use `sql/11_cleanup_unused.sql` and `sql/12_reset_dwh.sql` if you need to restart from a clean state.

## Rubric Alignment

### Staging

- **Architecture Diagram** – The `docs/` folder contains Mermaid definitions and exported diagrams showing the eight input files feeding STG → ODS → DWH → Reporting, satisfying the staging architecture requirement.
- **Load Yelp JSON** – `sql/03_copy_into_staging.sql` loads the six Yelp files into `STG.BUSINESS_RAW`, `STG.REVIEW_RAW`, `STG.CUSTOMER_RAW`, `STG.TIP_RAW`, `STG.CHECKIN_RAW`, `STG.COVID_RAW`. Screenshots of the successful COPY commands and row counts should accompany the report.
- **Load Climate CSVs** – The same script handles `temperature.csv.gz` and `precipitation.csv.gz`, populating `STG.TEMPERATURE_RAW` and `STG.PRECIPITATION_RAW`, with evidence captured via SnowSQL output.

### Operational Data Store

- **ER Diagram** – Provided in `docs/` (Mermaid + exported image) showing the required tables and relationships: Business, Customer, Tips, Review, Precipitation, Covid, Checkin, Temperature.
- **Transform Staging → ODS** – `sql/05_json_xforms.sql` performs the typed inserts from staging to ODS. Include a screenshot showing the `number of rows inserted` results.
- **JSON Expansion** – The same script demonstrates Snowflake JSON functions (`t.V:`, `TRY_TO_DATE`, `ARRAY_SIZE`) to flatten the semi-structured Yelp data. Capture query outputs comparing raw variant data vs. structured columns.
- **Compression Metrics** – `sql/09_metrics.sql` reports `ROW_COUNT` and `BYTES` by table for STG and ODS, enabling the staging vs. ODS comparison required by the rubric.
- **Integrate Climate + Yelp** – `sql/06_integrate_weather.sql` creates `ODS.REVIEW_WITH_WEATHER` and runs verification queries; include the SQL and the resulting row-count/state breakdown screenshot.

### Data Warehouse

- **Star Schema Diagram** – Included in `docs/` with dimensions (`DIM_DATE`, `DIM_BUSINESS`, `DIM_CUSTOMER`, `DIM_WEATHER`) and fact table (`FACT_REVIEW`).
- **ODS → DWH ETL** – `sql/07_dwh_star.sql` populates the star schema. Provide both the SQL and the final row-count summary screenshot.
- **Reporting Query** – `sql/08_report.sql` produces a report containing business name, review date, temperature, precipitation, and ratings. Capture the query and the SnowSQL output in the submission.

## Why Each Script Exists

| Script | Purpose | Rubric Connection |
|--------|---------|-------------------|
| `01_setup_env.sql` | Provision Snowflake warehouse, database, schemas, and file formats | Establishes environment for all rubric tasks |
| `02_staging_tables.sql` | Define raw staging tables for Yelp (VARIANT) and climate (typed CSV) | Prerequisite for staging loads |
| `03_copy_into_staging.sql` | COPY commands for six Yelp JSON files + two climate CSV files; validation SELECT | Staging requirements (load evidence) |
| `04_ods_build.sql` | Create typed ODS tables | Required before transformations |
| `05_json_xforms.sql` | Transform JSON/CSV staging data into ODS tables using Snowflake JSON functions; row-count check | ODS transformation and JSON expansion criteria |
| `06_integrate_weather.sql` | Join ODS reviews to weather via review date; validation SELECTs | Climate/Yelp integration |
| `07_dwh_star.sql` | Build star schema dimensions and load FACT_REVIEW; row-count summary | DWH design + ETL rubric items |
| `08_report.sql` | Reporting query showing business, temperature, precipitation, rating | Final reporting requirement |
| `09_metrics.sql` | Table-level row count & bytes for STG/ODS; stage listings | Compression comparison evidence |
| `11_cleanup_unused.sql` | (Optional) remove deprecated helper views/tables | Keeps Snowflake schemas clean between runs |
| `12_reset_dwh.sql` | (Optional) truncate DWH tables before rerun | Ensures “in order” execution for rubric |

## Notes

- The project assumes SnowSQL execution; adjust commands if using Worksheets or another client.
- Run scripts in order and capture outputs immediately for documentation.
- Keep the raw datasets outside version control. The repository is focused on Snowflake DDL/DML and supporting diagrams/screenshots.

## References

- [Yelp Open Dataset](https://business.yelp.com/data/resources/open-dataset/)
- [Yelp COVID-19 Features (Kaggle)](https://www.kaggle.com/claudiadodge/yelp-academic-data-set-covid-features?select=yelp_academic_dataset_covid_features.json)
- [Climate Explorer](https://crt-climate-explorer.nemac.org/)
- [Snowflake](https://www.snowflake.com/)
- [SnowSQL Install Guide](https://docs.snowflake.com/en/user-guide/snowsql-install-config.html)
- [SnowSQL Bootstrap Repository](https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/index.html)

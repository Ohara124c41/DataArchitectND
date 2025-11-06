# Tech ABC Corp - Human Resources Database

Comprehensive, normalized HR database for Tech ABC Corp, designed to replace the shared spreadsheet with a secure, role-aware, and scalable relational store. The project includes DDL to instantiate the schema, seed/ETL guidance from the Excel source, and stand-alone SQL scripts for verification, CRUD, security, and reporting. Note: This is a fictitious company for the Udacity Data Architect Nanodegree, as used in the MSc AI program.

## Scope and objectives

The database supports employee master data, organizations and locations, job titles, effective-dated assignments, and effective-dated salaries with strict access controls. It is built for operational integrity, least-privilege access to compensation, and future integration with payroll for PTO and attendance. Retention target is 7 years. Read-most workloads are expected, with company-wide read-only to non-salary views and write access restricted to HR and management. Growth assumptions: approximately 20 percent headcount growth with accumulating history.

## Repository layout

* sql/ddl.sql - creates schema, types, tables, keys, constraints, indexes, and views
* sql/crud/q1.sql ... q7.sql - verification and CRUD tasks
* sql/above_and_beyond/b1.sql ... b3.sql - optional extras (all-employee view, parameterized history function, enforcement patterns)
* docs/ - ERD exports and notes

## Prerequisites

* PostgreSQL 9.5 (tested on 9.5)
* psql client on PATH
* OS-agnostic shell access (PowerShell, cmd, bash, or zsh)

## Quick start - local PostgreSQL 9.5

Create the database and objects, then run verification scripts. Replace values for user, password, host, and database as needed.

```
createdb hrdb
psql -U "$USER" -d hrdb -f sql/ddl.sql
```

If using CSV seed data, load through staging and merge into core tables. Example loader sequence:

```
psql -U "$USER" -d hrdb -f sql/seed/01_create_staging.sql
psql -U "$USER" -d hrdb -f sql/seed/02_copy_from_csv.sql
psql -U "$USER" -d hrdb -f sql/seed/03_merge_staging_to_core.sql
```

Run verification and CRUD tasks individually to validate the build:

```
psql -q -U "$USER" -d hrdb -f sql/crud/q1.sql
psql -q -U "$USER" -d hrdb -f sql/crud/q2.sql
psql -q -U "$USER" -d hrdb -f sql/crud/q3.sql
psql -q -U "$USER" -d hrdb -f sql/crud/q4.sql
psql -q -U "$USER" -d hrdb -f sql/crud/q5.sql
psql -q -U "$USER" -d hrdb -f sql/crud/q6.sql
psql -q -U "$USER" -d hrdb -f sql/crud/q7.sql
```

Windows PowerShell example with explicit host:

```
psql -h localhost -U postgres -d hrdb -f sql\ddl.sql
psql -h localhost -U postgres -d hrdb -f sql\crud\q1.sql
```

## Running the verification scripts

Each script is self-contained and prints a result set that can be compared against expectations.

* q1.sql: list employees with job titles and department names
* q2.sql: insert a new job title Web Programmer
* q3.sql: correct Web Programmer to Web Developer
* q4.sql: delete Web Developer from the catalog
* q5.sql: employee counts per department
* q6.sql: current and past job history for a named employee including manager and dates
* q7.sql: narrative and example GRANTs showing how to isolate salary under role-based access

Parameterization pattern for q6.sql if a variant uses a name variable:

```
\set employee_name 'Toni Lembeck'
SELECT * FROM hr.get_employee_history(:'employee_name');
```

If using the above-and-beyond history function (b2.sql) on PostgreSQL 9.5, invoke as a function rather than a procedure:

```
SELECT * FROM hr.fn_get_employee_jobs('Toni Lembeck');
```

## Security model

Salary data is protected using least privilege, separation into a dedicated table, and grants limited to HR roles. Typical sequence:

```
REVOKE ALL ON SCHEMA hr FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA hr FROM PUBLIC;

CREATE ROLE hr_read;
CREATE ROLE hr_admin;
CREATE ROLE analyst;

GRANT USAGE ON SCHEMA hr TO hr_read, hr_admin, analyst;
GRANT SELECT ON hr.employee, hr.organization_unit, hr.job_title,
             hr.work_location, hr.employment_assignment
  TO hr_read, analyst, hr_admin;

GRANT SELECT, INSERT, UPDATE, DELETE ON hr.salary TO hr_admin;
GRANT SELECT ON hr.salary TO hr_read;
REVOKE ALL ON hr.salary FROM analyst;

GRANT SELECT ON hr.v_employee_current, hr.v_employee_flat
  TO hr_read, analyst, hr_admin;
```

Optional row-level security is available in PostgreSQL 9.5:

```
ALTER TABLE hr.employment_assignment ENABLE ROW LEVEL SECURITY;
CREATE POLICY p_mgr_only ON hr.employment_assignment
  USING (manager_id = current_setting('hr.current_manager_id')::int);
```

Writes can be funneled through SECURITY DEFINER functions for auditability, with application code setting a session variable for manager context.

## ETL guidance

Import the Excel workbook into staging with strict typing and date parsing, then deduplicate and conform values before merging to core tables. Enforce referential integrity by loading lookups first, then employees, then assignments, then salaries. Use effective dating rules to prevent overlap. Preserve original source keys in staging for lineage. PostgreSQL 9.5 supports UPSERT via ON CONFLICT, which can be used during merges where a natural key exists.

## ERDs

Three ERDs document the progression from conceptual to logical to physical with 3NF and crow's-foot notation at the physical layer. Exported diagrams are provided in docs/. They illustrate surrogate keys, foreign keys, and effective dating for assignments and salaries, along with public views and security boundaries.

## Backups and retention

Classify as Critical. Execute weekly full and daily incremental backups and verify recovery regularly. Retain operational records for at least 7 years. Use encryption at rest and in transit according to organizational policy.

## Testing and CI hooks

Validation consists of compiling the schema, loading seed data, and running q1 to q7 to verify joins, constraints, and security behavior. Continuous integration can invoke psql non-interactively against a PostgreSQL 9.5 service, executing sql/ddl.sql and the q*.sql scripts on each push.

## Troubleshooting

If a foreign key creation fails, confirm referenced tables exist and are populated if NOT VALID is not used. For CSV imports, ensure consistent encodings, header presence, delimiter choice, and date formats. On Windows shells, use double quotes where appropriate and escape backslashes carefully. If psql reports missing privileges, re-apply the GRANT statements and verify the active role with SELECT current_user, session_user.

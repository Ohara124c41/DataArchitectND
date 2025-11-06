-- Clean init
DROP VIEW IF EXISTS v_employee_current CASCADE;
DROP TABLE IF EXISTS salary CASCADE;
DROP TABLE IF EXISTS employment_assignment CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS location CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS job_title CASCADE;

-- Dimensions
CREATE TABLE job_title (
  job_title_id SERIAL PRIMARY KEY,
  job_title_nm VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE department (
  department_id SERIAL PRIMARY KEY,
  department_nm VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE location (
  location_id  SERIAL PRIMARY KEY,
  location_nm  VARCHAR(50) NOT NULL,
  address      VARCHAR(100),
  city         VARCHAR(50),
  state        CHAR(2),
  CONSTRAINT uq_location UNIQUE (location_nm, address, city, state)
);

-- Core entity
CREATE TABLE employee (
  emp_id         VARCHAR(8)  PRIMARY KEY,
  emp_nm         VARCHAR(50) NOT NULL,
  email          VARCHAR(100),
  hire_dt        DATE,
  education_lvl  VARCHAR(50)
);

-- Effective-dated assignment history
CREATE TABLE employment_assignment (
  assignment_id   BIGSERIAL PRIMARY KEY,
  emp_id          VARCHAR(8)  NOT NULL REFERENCES employee(emp_id),
  job_title_id    INT         NOT NULL REFERENCES job_title(job_title_id),
  department_id   INT         NOT NULL REFERENCES department(department_id),
  manager_emp_id  VARCHAR(8)  REFERENCES employee(emp_id),
  location_id     INT         NOT NULL REFERENCES location(location_id),
  start_dt        DATE        NOT NULL,
  end_dt          DATE        NOT NULL
);

-- Salary table 
CREATE TABLE salary (
  salary_id   BIGSERIAL PRIMARY KEY,
  emp_id      VARCHAR(8) NOT NULL REFERENCES employee(emp_id),
  salary_amt  INT        NOT NULL,
  start_dt    DATE       NOT NULL,
  end_dt      DATE       NOT NULL
);

-- View for current rows
CREATE VIEW v_employee_current AS
SELECT a.assignment_id, e.emp_id, e.emp_nm, e.email, e.hire_dt, e.education_lvl,
       jt.job_title_nm, d.department_nm, l.location_nm, l.address, l.city, l.state,
       a.start_dt, a.end_dt, a.manager_emp_id
FROM employment_assignment a
JOIN employee   e  ON e.emp_id = a.emp_id
JOIN job_title  jt ON jt.job_title_id = a.job_title_id
JOIN department d  ON d.department_id = a.department_id
JOIN location   l  ON l.location_id  = a.location_id
WHERE a.end_dt >= CURRENT_DATE;

CREATE INDEX idx_assign_emp ON employment_assignment(emp_id, end_dt);
CREATE INDEX idx_assign_mgr ON employment_assignment(manager_emp_id);

-- Implement column-level security to restrict salary for a non-management user "NoMgr"

-- 1) Create the login role if it does not exist
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'NoMgr') THEN
    CREATE ROLE "NoMgr" LOGIN PASSWORD 'change_me';
  END IF;
END
$do$;

-- 2) Allow the user to connect to this database and use the public schema
DO $do$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO "NoMgr"', current_database());
END
$do$;
GRANT USAGE ON SCHEMA public TO "NoMgr";

-- 3) Ensure table-level access is not blanket granted
REVOKE ALL ON TABLE public.proj_stg FROM PUBLIC;
REVOKE ALL ON TABLE public.proj_stg FROM "NoMgr";

-- 4) Grant SELECT on all non-sensitive columns, but not on salary
GRANT SELECT (
  emp_id,
  emp_nm,
  email,
  hire_dt,
  job_title,
  department_nm,
  manager,
  start_dt,
  end_dt,
  location,
  address,
  city,
  state,
  education_lvl
) ON public.proj_stg TO "NoMgr";

-- 5) Optional verification: switch to NoMgr and show permitted columns
SET ROLE "NoMgr";
SELECT emp_id, emp_nm, job_title, department_nm, start_dt, end_dt
FROM public.proj_stg
ORDER BY emp_id
LIMIT 10;

-- Attempting to select salary will fail with insufficient privilege.
-- The following block catches the error and surfaces a NOTICE instead of aborting.
DO $do$
DECLARE r record;
BEGIN
  BEGIN
    EXECUTE 'SELECT emp_id, salary FROM public.proj_stg LIMIT 1' INTO r;
    RAISE NOTICE 'Unexpectedly succeeded in selecting salary.';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'As expected, selecting salary is blocked for role "NoMgr".';
    WHEN OTHERS THEN
      RAISE NOTICE 'Unexpected error while testing salary access: %', SQLERRM;
  END;
END
$do$;

RESET ROLE;

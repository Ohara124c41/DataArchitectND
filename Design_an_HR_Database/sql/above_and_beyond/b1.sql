CREATE OR REPLACE VIEW public.vw_employee_all AS
SELECT
    emp_id, emp_nm, email, hire_dt, job_title, salary,
    department_nm, manager, start_dt, end_dt, location,
    address, city, state, education_lvl
FROM public.proj_stg;

SELECT *
FROM public.vw_employee_all
ORDER BY emp_id;

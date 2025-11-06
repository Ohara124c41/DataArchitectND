CREATE OR REPLACE FUNCTION public.get_employee_jobs(p_emp_nm text)
RETURNS TABLE (
    emp_nm text,
    job_title text,
    department_nm text,
    manager text,
    start_dt date,
    end_dt date
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        emp_nm,
        job_title,
        department_nm,
        manager,
        start_dt,
        end_dt
    FROM public.proj_stg
    WHERE emp_nm ILIKE p_emp_nm
    ORDER BY start_dt;
$$;

-- Execute for the requested employee
SELECT * FROM public.get_employee_jobs('Toni Lembeck');

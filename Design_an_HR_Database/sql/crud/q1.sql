SELECT e.emp_id, e.emp_nm, v.job_title_nm, v.department_nm
FROM v_employee_current v
JOIN employee e ON e.emp_id = v.emp_id
ORDER BY e.emp_nm;

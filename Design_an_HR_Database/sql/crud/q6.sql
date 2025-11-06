SELECT e.emp_nm,
       jt.job_title_nm,
       d.department_nm,
       COALESCE(m.emp_nm, 'None') AS manager_nm,
       a.start_dt,
       a.end_dt
FROM employment_assignment a
JOIN employee e   ON e.emp_id = a.emp_id
JOIN job_title jt ON jt.job_title_id = a.job_title_id
JOIN department d ON d.department_id = a.department_id
LEFT JOIN employee m ON m.emp_id = a.manager_emp_id
WHERE e.emp_nm = 'Toni Lembeck'
ORDER BY a.start_dt;
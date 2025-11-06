SELECT v.department_nm, COUNT(*) AS headcount
FROM v_employee_current v
GROUP BY v.department_nm
ORDER BY v.department_nm;
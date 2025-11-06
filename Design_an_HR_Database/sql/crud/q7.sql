SELECT 'analyst' AS role,
       has_table_privilege('analyst','salary','SELECT') AS can_select_salary,
       has_table_privilege('analyst','v_employee_public','SELECT') AS can_select_public_view
UNION ALL
SELECT 'mgr',
       has_table_privilege('mgr','salary','SELECT'),
       has_table_privilege('mgr','v_employee_public','SELECT')
UNION ALL
SELECT 'hr',
       has_table_privilege('hr','salary','SELECT'),
       has_table_privilege('hr','v_employee_public','SELECT');
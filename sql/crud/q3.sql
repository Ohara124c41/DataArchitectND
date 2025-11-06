WITH upd AS (
  UPDATE job_title
  SET job_title_nm = 'Web Developer'
  WHERE job_title_nm = 'Web Programmer'
  RETURNING job_title_id, job_title_nm
)
SELECT * FROM upd;

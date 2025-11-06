WITH del AS (
  DELETE FROM job_title
  WHERE job_title_nm = 'Web Developer'
  RETURNING job_title_id, job_title_nm
)
SELECT * FROM del;
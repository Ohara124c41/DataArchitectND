WITH ins AS (
  INSERT INTO job_title(job_title_nm)
  VALUES ('Web Programmer')
  ON CONFLICT (job_title_nm) DO UPDATE
    SET job_title_nm = EXCLUDED.job_title_nm
  RETURNING job_title_id, job_title_nm
)
SELECT * FROM ins;
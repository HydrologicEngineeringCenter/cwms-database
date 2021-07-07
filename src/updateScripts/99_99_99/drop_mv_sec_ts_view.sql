drop materialized view mv_sec_ts_privileges;

BEGIN
  SYS.DBMS_SCHEDULER.DROP_JOB
    (job_name  => '&cwms_schema..REFRESH_MV_SEC_TS_PRIVS_JOB');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

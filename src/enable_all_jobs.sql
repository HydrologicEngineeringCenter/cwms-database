BEGIN
   FOR c IN (SELECT owner, job_name
               FROM dba_scheduler_jobs
              WHERE owner = '&cwms_schema')
   LOOP
      BEGIN
         DBMS_OUTPUT.PUT_LINE (c.job_name);
         DBMS_SCHEDULER.ENABLE (c.owner || '.' || c.job_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/

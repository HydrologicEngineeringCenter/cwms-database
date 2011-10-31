set time on
set echo off
set define on
set serveroutput on
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept cwms_schema  char prompt 'Enter cwms schema name    : '
accept cwms_passwd  char prompt 'Enter the password for cwms  schema   : '
accept cwms_dir  char prompt 'Enter directory for storing export file   : '
set echo &echo_state

spool exportCWMS_DB.log
--
-- log on as sysdba
--
connect &cwms_schema/&cwms_passwd@&inst
select sysdate from dual;
whenever sqlerror exit sql.sqlcode;

set serveroutput on
declare
   ind            NUMBER;                                        -- Loop index
   h1             NUMBER;                              -- Data Pump job handle
   percent_done   NUMBER;                        -- Percentage of job complete
   job_state      VARCHAR2 (30);                 -- To keep track of job state
   le             ku$_LogEntry;                  -- For WIP and error messages
   js             ku$_JobStatus;             -- The job status from get_status
   jd             ku$_JobDesc;          -- The job description from get_status
   sts            ku$_Status;      -- The status object returned by get_status
  
begin
  
   -- Create a (user-named) Data Pump job to do a schema export.

   h1 :=
      DBMS_DATAPUMP.OPEN ('EXPORT',
                          'SCHEMA',
                          NULL,
                          'CWMS_EXPORT',
                          'LATEST');

   -- Specify a single dump file for the job (using the handle just returned)
   -- and a directory object, which must already be defined and accessible
   -- to the user running this procedure.

   EXECUTE IMMEDIATE 'create or replace directory expdp_dir as ''&cwms_dir''';
   
   BEGIN
     UTL_FILE.FREMOVE('EXPDP_DIR','cwms_at_data-bak.dmp');
    EXCEPTION 
    WHEN OTHERS
    THEN
         DBMS_OUTPUT.put_line (SQLERRM);
      dbms_output.put_line( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END;
  
  BEGIN
    UTL_FILE.FRENAME('EXPDP_DIR','cwms_at_data.dmp','EXPDP_DIR','cwms_at_data-bak.dmp');
    EXCEPTION 
    WHEN OTHERS
    THEN
         DBMS_OUTPUT.put_line (SQLERRM);
      dbms_output.put_line( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END;
  
   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_at_data.dmp', 'EXPDP_DIR');

   -- A metadata filter is used to specify the schema that will be exported.
  
   
     
   DBMS_DATAPUMP.METADATA_FILTER (h1,'INCLUDE_PATH_EXPR','IN (''SEQUENCE'',''TABLE'')' );
   DBMS_DATAPUMP.METADATA_FILTER (h1,'NAME_EXPR', 'IN (SELECT  table_name from dba_tables where owner = ''&cwms_schema'' and table_name like ''AT_%'' )','TABLE'  );
   

   DBMS_DATAPUMP.START_JOB (h1);

   -- The export job should now be running. In the following loop, the job
   -- is monitored until it completes. In the meantime, progress information is
   -- displayed.

   percent_done := 0;
   job_state := 'UNDEFINED';

   WHILE (job_state != 'COMPLETED') AND (job_state != 'STOPPED')
   LOOP
      DBMS_DATAPUMP.
      get_status (
         h1,
           DBMS_DATAPUMP.ku$_status_job_error
         + DBMS_DATAPUMP.ku$_status_job_status
         + DBMS_DATAPUMP.ku$_status_wip,
         -1,
         job_state,
         sts);
      js := sts.job_status;

      -- If the percentage done changed, display the new value.

      IF js.percent_done != percent_done
      THEN
         DBMS_OUTPUT.
         put_line ('*** Job percent done = ' || TO_CHAR (js.percent_done));
         percent_done := js.percent_done;
      END IF;

      -- If any work-in-progress (WIP) or error messages were received for the job,
      -- display them.

      IF (BITAND (sts.mask, DBMS_DATAPUMP.ku$_status_wip) != 0)
      THEN
         le := sts.wip;
      ELSE
         IF (BITAND (sts.mask, DBMS_DATAPUMP.ku$_status_job_error) != 0)
         THEN
            le := sts.error;
         ELSE
            le := NULL;
         END IF;
      END IF;

      IF le IS NOT NULL
      THEN
         ind := le.FIRST;

         WHILE ind IS NOT NULL
         LOOP
            DBMS_OUTPUT.put_line (le (ind).LogText);
            ind := le.NEXT (ind);
         END LOOP;
      END IF;
   END LOOP;

   -- Indicate that the job finished and detach from it.

   DBMS_OUTPUT.put_line ('Job has completed');
   DBMS_OUTPUT.put_line ('Final job state = ' || job_state);
   DBMS_DATAPUMP.detach (h1);

  
EXCEPTION
   WHEN OTHERS
   THEN
   
      DBMS_OUTPUT.put_line (SQLERRM);
      dbms_output.put_line( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      DBMS_DATAPUMP.detach (h1);
      RAISE;
END EXPORT_CWMS_AT_DATA;
/
exit 0

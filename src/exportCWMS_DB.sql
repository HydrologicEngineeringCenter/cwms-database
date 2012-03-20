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
accept sys_passwd  char prompt 'Enter the password for SYS     : '
accept cwms_dir  char prompt 'Enter directory for storing export file   : '
accept oracle_parallel  char prompt 'Enter number of oracle export jobs (1-9)   : '
set echo &echo_state

spool exportCWMS_DB.log
--
-- log on as sysdba
--
whenever sqlerror exit sql.sqlcode;
connect sys/&sys_passwd@&inst as sysdba
set serveroutput on
select sysdate from dual;
begin execute immediate 'ALTER SYSTEM ENABLE RESTRICTED SESSION'; end;
/

begin
    for c in (select owner,job_name from dba_scheduler_jobs where owner = '&cwms_schema' or owner = 'CCP')
    loop
        DBMS_OUTPUT.PUT_LINE(c.job_name);
        dbms_scheduler.drop_job(c.owner||'.'||c.job_name,true);
    end loop;
end;
/


DECLARE
   h1                  NUMBER;                         -- Data Pump job handle

   data_export_state   VARCHAR2 (30);                 -- Status of export jobs
   data_filename       VARCHAR2 (1024);
   export_exception   EXCEPTION;


   PROCEDURE WRITE_DATAFILE
   IS
      ft   UTL_FILE.file_type;
   BEGIN
      BEGIN
         UTL_FILE.fremove ('EXPDP_DIR', 'datafile_define.sql');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
      END;

      ft := UTL_FILE.fopen ('EXPDP_DIR', 'datafile_define.sql', 'w');

      FOR C IN (SELECT file_name
                  FROM dba_data_files
                 WHERE tablespace_name = 'CWMS_20_TSV')
      LOOP
         UTL_FILE.put_line (ft, c.file_name);
      END LOOP;

      UTL_FILE.fclose (ft);
   END WRITE_DATAFILE;

   PROCEDURE DISABLE_FK_CONSTRAINTS
   IS
   BEGIN
      FOR c
         IN (  SELECT c.owner, c.table_name, c.constraint_name
                 FROM dba_constraints c, dba_tables t
                WHERE     c.table_name = t.table_name
                      AND c.status = 'ENABLED'
                      AND c.owner = '&cwms_schema'
                      AND c.constraint_type = 'R'
             ORDER BY c.constraint_type DESC)
      LOOP
         DBMS_UTILITY.exec_ddl_statement (
               'alter table '
            || c.owner
            || '.'
            || c.table_name
            || ' disable constraint '
            || c.constraint_name);
      END LOOP;

   END DISABLE_FK_CONSTRAINTS;

   PROCEDURE ENABLE_FK_CONSTRAINTS
   IS
   BEGIN

      FOR c
         IN (  SELECT c.owner, c.table_name, c.constraint_name
                 FROM dba_constraints c, dba_tables t
                WHERE     c.table_name = t.table_name
                      AND c.status = 'DISABLED'
                      AND c.owner = '&cwms_schema'
                      AND c.constraint_type = 'R'
             ORDER BY c.constraint_type DESC)
      LOOP
         DBMS_UTILITY.exec_ddl_statement (
               'alter table '
            || c.owner
            || '.'
            || c.table_name
            || ' enable constraint '
            || c.constraint_name);
      END LOOP;
   END ENABLE_FK_CONSTRAINTS;

   PROCEDURE RENAME_BACKUP_FILE (FNAME VARCHAR2)
   IS
   BEGIN
      BEGIN
         UTL_FILE.FREMOVE ('EXPDP_DIR', FNAME || '_bak.dmp');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
            DBMS_OUTPUT.PUT_LINE (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;

      BEGIN
         UTL_FILE.FRENAME ('EXPDP_DIR',
                           FNAME || '.dmp',
                           'EXPDP_DIR',
                           FNAME || '_bak.dmp');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (SQLERRM);
            DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
   END RENAME_BACKUP_FILE;

   FUNCTION CHECK_STATUS (handle NUMBER)
      RETURN VARCHAR2
   IS
      ind            NUMBER;
      percent_done   NUMBER;                     -- Percentage of job complete
      job_state      VARCHAR2 (30);              -- To keep track of job state
      le             ku$_LogEntry;               -- For WIP and error messages
      js             ku$_JobStatus;          -- The job status from get_status
      jd             ku$_JobDesc;       -- The job description from get_status
      sts            ku$_Status;   -- The status object returned by get_status
   BEGIN
      percent_done := 0;
      job_state := 'UNDEFINED';

      WHILE (job_state != 'COMPLETED') AND (job_state != 'STOPPED')
      LOOP
         DBMS_DATAPUMP.get_status (
            handle,
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
            DBMS_OUTPUT.put_line (
               '*** Job percent done = ' || TO_CHAR (js.percent_done));
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

      RETURN job_state;
   END CHECK_STATUS;
BEGIN
   EXECUTE IMMEDIATE 'create or replace directory expdp_dir as ''&cwms_dir''';
   DISABLE_FK_CONSTRAINTS;
   --EXECUTE IMMEDIATE 'ALTER TABLE ' || '&CWMS_SCHEMA' || '.CWMS_DATA_QUALITY MOVE TABLESPACE CWMS_20_TSV';
   --EXECUTE IMMEDIATE 'ALTER TABLE ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC MOVE TABLESPACE CWMS_20_TSV';
   --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC_PK REBUILD TABLESPACE CWMS_20_TSV';
   --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC_UI REBUILD TABLESPACE CWMS_20_TSV';
   --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.CWMS_DATA_QUALITY_PK REBUILD TABLESPACE CWMS_20_TSV';
   WRITE_DATAFILE;

   h1 :=
      DBMS_DATAPUMP.OPEN ('EXPORT',
                          'TABLE',
                          NULL,
                          NULL,
                          'LATEST');

   -- Specify a single dump file for the job (using the handle just returned)
   -- and a directory object, which must already be defined and accessible
   -- to the user running this procedure.




   RENAME_BACKUP_FILE ('cwms_at_data');

   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_at_data.dmp', 'EXPDP_DIR');

   -- A metadata filter is used to specify the schema that will be exported.

   DBMS_DATAPUMP.METADATA_FILTER (h1,
                                  'SCHEMA_EXPR',
                                  'IN (''&cwms_schema'')');

   DBMS_DATAPUMP.SET_PARAMETER (h1, 'INCLUDE_METADATA', 0);
   DBMS_DATAPUMP.METADATA_FILTER (
      h1,
      'NAME_EXPR',
      'IN (SELECT  table_name from dba_tables where owner = ''&cwms_schema'' and table_name like ''AT_%'' and table_name not like ''AT_TSV_%'' and table_name not like ''AT_TS_MSG_ARCHIVE%'' and table_name not like ''AT_LOG_MESSAGE%'')');
   DBMS_DATAPUMP.START_JOB (h1);
   data_export_state := CHECK_STATUS (h1);
   DBMS_OUTPUT.put_line ('AT Export Job has completed');
   DBMS_OUTPUT.put_line ('Final job state(AT export) = ' || data_export_state);
   DBMS_DATAPUMP.detach (h1);
   IF data_export_state != 'COMPLETED'
   THEN
	RAISE export_exception;
   END IF;

   h1 :=
      DBMS_DATAPUMP.OPEN ('EXPORT',
                          'SCHEMA',
                          NULL,
                          NULL,
                          'LATEST');
   RENAME_BACKUP_FILE ('cwms_seq_data');

   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_seq_data.dmp', 'EXPDP_DIR');

   DBMS_DATAPUMP.METADATA_FILTER (h1,
                                  'SCHEMA_EXPR',
                                  'IN (''&cwms_schema'')');

   DBMS_DATAPUMP.METADATA_FILTER (h1,
                                  'INCLUDE_PATH_EXPR',
                                  'IN (''SEQUENCE'')');

   DBMS_DATAPUMP.METADATA_FILTER (
      h1,
      'NAME_EXPR',
      'IN (SELECT  sequence_name from dba_sequences where sequence_owner = ''&cwms_schema'' and sequence_name like ''CWMS_SEQ%'' )',
      'SEQUENCE');


   DBMS_DATAPUMP.START_JOB (h1);
   data_export_state := CHECK_STATUS (h1);
   DBMS_OUTPUT.put_line ('Sequence export Job has completed');
   DBMS_OUTPUT.put_line ('Final job state(sequence export) = ' || data_export_state);
   DBMS_DATAPUMP.detach (h1);
   IF data_export_state != 'COMPLETED'
   THEN
	RAISE export_exception;
   END IF;
   RENAME_BACKUP_FILE ('cwms_at_tsv');
   EXECUTE IMMEDIATE 'ALTER TABLESPACE CWMS_20_TSV read only';

   h1 :=
      DBMS_DATAPUMP.OPEN ('EXPORT',
                          'TRANSPORTABLE',
                          NULL,
                          NULL);

   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_at_tsv.dmp', 'EXPDP_DIR');
   DBMS_DATAPUMP.METADATA_FILTER (h1,
                                  'TABLESPACE_EXPR',
                                  'IN (''CWMS_20_TSV'')');
   DBMS_DATAPUMP.START_JOB (h1);
   data_export_state := CHECK_STATUS (h1);
   DBMS_OUTPUT.put_line ('Tablespace export Job has completed');
   DBMS_OUTPUT.put_line ('Final job state(Tablespace) = ' || data_export_state);
   DBMS_DATAPUMP.detach (h1);
   IF data_export_state != 'COMPLETED'
   THEN
	RAISE export_exception;
   END IF;
   --ENABLE_FK_CONSTRAINTS;


EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line (SQLERRM);
      DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      DBMS_DATAPUMP.detach (h1);
      --ENABLE_FK_CONSTRAINTS;
      RAISE;
END EXPORT_CWMS_AT_DATA;
/

BEGIN
	execute immediate 'drop tablespace CWMS_20_TSV including contents keep datafiles cascade constraints';
 
	execute immediate 'create  tablespace CWMS_20_TSV datafile autoextend on';
	execute immediate 'ALTER SYSTEM DISABLE RESTRICTED SESSION';
END;
/
exit 0

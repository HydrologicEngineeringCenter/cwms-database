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
accept cwms_dir  char prompt 'Enter the directory containing exported file     : '
accept oracle_parallel  char prompt 'Enter number of oracle export jobs (1-9)   : '
set echo &echo_state

spool importCWMS_DB.log
whenever sqlerror exit sql.sqlcode;


--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
set serveroutput on
select sysdate from dual;
begin execute immediate 'ALTER SYSTEM ENABLE RESTRICTED SESSION'; end;
/

begin
    for c in (select owner,job_name from dba_scheduler_jobs where owner = 'CWMS_20' or owner = 'CCP')
    loop
        DBMS_OUTPUT.PUT_LINE(c.job_name);
        dbms_scheduler.drop_job(c.owner||'.'||c.job_name,true);
    end loop;
end;
/

DECLARE
   h1             NUMBER;                              -- Data Pump job handle
   data_export_state VARCHAR2 (30);                 -- To keep track of job state
   data_import_state   VARCHAR2 (30);                 -- Status of export jobs
  

   PROCEDURE ADD_DATAFILE_NAMES(h NUMBER)
   IS
      ft              UTL_FILE.file_type;
      datafile_name   varchar2(1028);
   BEGIN
      ft := UTL_FILE.fopen ('EXPDP_DIR', 'datafile_define.sql', 'r');

      WHILE true
      LOOP
        BEGIN
            UTL_FILE.GET_LINE (ft, datafile_name);
            DBMS_OUTPUT.PUT_LINE ('data file: ' || datafile_name);
            DBMS_DATAPUMP.SET_PARAMETER (h, 'TABLESPACE_DATAFILE', datafile_name);
        EXCEPTION
            WHEN OTHERS THEN
                 UTL_FILE.fclose (ft);
                 RETURN;
       END;
      END LOOP;
   END;

   FUNCTION CHECK_STATUS (handle NUMBER)
      RETURN VARCHAR2
   IS
      ind            NUMBER;                                        -- Loop index
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

   PROCEDURE CLEANUP
   IS
   BEGIN
	-- Enable all foreign contraints
 	FOR c IN
  		(SELECT c.owner, c.table_name, c.constraint_name
   		FROM dba_constraints c, dba_tables t
   		WHERE c.table_name = t.table_name
   		AND c.status = 'DISABLED'
   		AND c.owner = '&cwms_schema'
   		AND c.constraint_type = 'R'
                AND c.table_name not like 'AT_TSV%'
   		ORDER BY c.constraint_type DESC)
  	LOOP
    		dbms_utility.exec_ddl_statement('alter table ' || c.owner || '.' || c.table_name || ' enable constraint ' || c.constraint_name);
  	END LOOP;
  	-- enable all triggers
  	FOR t IN
  		(SELECT t.table_owner, t.table_name, t.trigger_name
   		FROM dba_triggers t
   		WHERE
   		t.status = 'DISABLED'
   		AND t.table_owner = '&cwms_schema'
   		)
  	LOOP
    		dbms_utility.exec_ddl_statement('alter trigger ' ||  t.table_owner || '.' || t.trigger_name || ' enable');
  	END LOOP;

	execute immediate 'ALTER SYSTEM DISABLE RESTRICTED SESSION';

   END CLEANUP;

  BEGIN
   for rec in (select sequence_name from all_sequences where sequence_name like 'CWMS_SEQ%')
   loop
	execute immediate 'drop sequence &cwms_schema' || '.' || rec.sequence_name;
   end loop;

  -- disable all foreign constraints
  FOR c IN
  (SELECT c.owner, c.table_name, c.constraint_name
   FROM dba_constraints c, dba_tables t
   WHERE c.table_name = t.table_name
   AND c.status = 'ENABLED'
   AND c.owner = '&cwms_schema'
   AND c.constraint_type = 'R'
   AND c.table_name not like 'AT_TSV%'
   ORDER BY c.constraint_type DESC)
  LOOP
    dbms_utility.exec_ddl_statement('alter table ' || c.owner || '.' || c.table_name || ' disable constraint ' || c.constraint_name);
  END LOOP;
  -- disable all triggers 
  FOR t IN
  (SELECT t.table_owner, t.table_name, t.trigger_name
   FROM dba_triggers t
   WHERE 
   t.status = 'ENABLED'
   AND t.table_owner = '&cwms_schema'
   )
  LOOP
    dbms_utility.exec_ddl_statement('alter trigger ' ||   t.table_owner || '.' || t.trigger_name || ' disable'); 
  END LOOP;

   execute immediate 'create or replace directory EXPDP_DIR as ''&cwms_dir''';


   h1 :=
      DBMS_DATAPUMP.OPEN ('IMPORT',
                          'TABLE',
			   NULL,
			   null 
                          );
   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_at_data.dmp', 'EXPDP_DIR');
   DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','TRUNCATE');
   DBMS_DATAPUMP.START_JOB (h1);

   data_export_state := CHECK_STATUS (h1);
   -- Indicate that the job finished and detach from it.

   DBMS_OUTPUT.put_line ('AT import job has completed');
   DBMS_OUTPUT.put_line ('Final job state (AT import) = ' || data_export_state);
   DBMS_DATAPUMP.detach (h1);

   h1 :=
      DBMS_DATAPUMP.OPEN ('IMPORT',
                          'SCHEMA',
			   NULL,
			   null 
                          );
   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_seq_data.dmp', 'EXPDP_DIR');
   DBMS_DATAPUMP.START_JOB (h1);

   data_export_state := CHECK_STATUS (h1);
   -- Indicate that the job finished and detach from it.

   DBMS_OUTPUT.put_line ('Sequence import job has completed');
   DBMS_OUTPUT.put_line ('Final job state (Sequence import) = ' || data_export_state);
   DBMS_DATAPUMP.detach (h1);

   EXECUTE IMMEDIATE 'drop tablespace cwms_20_tsv including contents cascade constraints';

   h1 :=
      DBMS_DATAPUMP.OPEN ('IMPORT',
                          'TRANSPORTABLE',
                          NULL,
                          NULL);
   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_at_tsv.dmp', 'EXPDP_DIR');
   --DBMS_DATAPUMP.SET_PARAMETER (h1, 'TABLESPACE_DATAFILE', get_datafile_name);
   --DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','TRUNCATE');
   ADD_DATAFILE_NAMES(h1);
   DBMS_DATAPUMP.START_JOB (h1);

   data_import_state := CHECK_STATUS (h1);

   DBMS_OUTPUT.PUT_LINE ('Import state(Tablespace import):' || data_import_state);
   DBMS_DATAPUMP.detach (h1);

   
   EXECUTE IMMEDIATE 'alter tablespace cwms_20_tsv read write';
   
   
   utl_recomp.recomp_serial('&cwms_schema');
   BEGIN
   	EXECUTE IMMEDIATE 'CREATE TABLE ' || '&cwms_schema' || '.AT_TS_DELETED_TIMES ( DELETED_TIME NUMBER(14) NOT NULL, TS_CODE NUMBER(10) NOT NULL, VERSION_DATE DATE NOT NULL, DATE_TIME DATE NOT NULL, CONSTRAINT AT_TS_DELETED_TIMES_PK PRIMARY KEY (DELETED_TIME, TS_CODE, VERSION_DATE, DATE_TIME)) ORGANIZATION INDEX LOGGING TABLESPACE CWMS_20_TSV PCTFREE 10 INITRANS 2 MAXTRANS   255 STORAGE    ( INITIAL          64K NEXT             1M MINEXTENTS       1 MAXEXTENTS       UNLIMITED PCTINCREASE      0 BUFFER_POOL      DEFAULT) NOPARALLEL MONITORING';
   	EXECUTE IMMEDIATE 'COMMENT ON TABLE' || '&cwms_schema' || '.AT_TS_DELETED_TIMES IS ''Contains times of recently deleted time series data in Java milliseconds''';
   	EXECUTE IMMEDIATE 'COMMENT ON COLUMN' || '&cwms_schema' || '.AT_TS_DELETED_TIMES.DELETED_TIME IS ''Time at which the data were deleted''';
   	EXECUTE IMMEDIATE 'COMMENT ON COLUMN' || '&cwms_schema' || '.AT_TS_DELETED_TIMES.TS_CODE IS ''TS_CODE of the deleted data''';
   EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.put_line (SQLERRM);
      		dbms_output.put_line( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
   END;



   --EXECUTE IMMEDIATE 'ALTER TABLE ' || '&CWMS_SCHEMA' || '.CWMS_DATA_QUALITY MOVE TABLESPACE CWMS_20DATA';
   --EXECUTE IMMEDIATE 'ALTER TABLE ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC MOVE TABLESPACE CWMS_20AT_DATA';
   --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC_PK REBUILD TABLESPACE CWMS_20DATA';
   --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC_UI REBUILD TABLESPACE CWMS_20AT_DATA';
   --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.CWMS_DATA_QUALITY_PK REBUILD TABLESPACE CWMS_20DATA';

   CLEANUP();
   EXCEPTION 
	WHEN OTHERS THEN
		CLEANUP();
   		DBMS_DATAPUMP.detach (h1);
	        DBMS_OUTPUT.put_line (SQLERRM);
                DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		RAISE;
		
END;
/

connect &cwms_schema/&cwms_passwd@&inst

exec cwms_msg.start_trim_log_job;
exec cwms_msg.start_purge_queues_job;
exec cwms_schema.cleanup_schema_version_table;
exec cwms_schema.start_check_schema_job;
exec cwms_ts.start_trim_ts_deleted_job;
exec cwms_sec.start_refresh_mv_sec_privs_job;
exec cwms_shef.start_update_shef_spec_map_job;

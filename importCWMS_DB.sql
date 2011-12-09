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
set echo &echo_state

spool importCWMS_DB.log
--
-- log on as sysdba
--
connect &cwms_schema/&cwms_passwd@&inst
select sysdate from dual;


set serveroutput on

DECLARE
  ind            NUMBER;                                        -- Loop index
   h1             NUMBER;                              -- Data Pump job handle
   percent_done   NUMBER;                        -- Percentage of job complete
   job_state      VARCHAR2 (30);                 -- To keep track of job state
   le             ku$_LogEntry;                  -- For WIP and error messages
   js             ku$_JobStatus;             -- The job status from get_status
   jd             ku$_JobDesc;          -- The job description from get_status
   sts            ku$_Status;      -- The status object returned by get_status
  


   PROCEDURE CLEANUP
   IS
   BEGIN
	-- Enable all foreign contraints
 	FOR c IN
  		(SELECT c.owner, c.table_name, c.constraint_name
   		FROM user_constraints c, user_tables t
   		WHERE c.table_name = t.table_name
   		AND c.status = 'DISABLED'
   		AND c.owner = '&cwms_schema'
   		AND c.constraint_type = 'R'
   		ORDER BY c.constraint_type DESC)
  	LOOP
    		dbms_utility.exec_ddl_statement('alter table ' || c.owner || '.' || c.table_name || ' enable constraint ' || c.constraint_name);
  	END LOOP;
  	-- enable all triggers
  		FOR t IN
  		(SELECT t.table_owner, t.table_name, t.trigger_name
   		FROM user_triggers t
   		WHERE
   		t.status = 'DISABLED'
   		AND t.table_owner = '&cwms_schema'
   		)
  	LOOP
    		dbms_utility.exec_ddl_statement('alter trigger ' ||  t.trigger_name || ' enable');
  	END LOOP;

   END CLEANUP;

  BEGIN
   for rec in (select sequence_name from all_sequences where sequence_name like 'CWMS%')
   loop
	execute immediate 'drop sequence ' || rec.sequence_name;
   end loop;

  -- disable all foreign constraints
  FOR c IN
  (SELECT c.owner, c.table_name, c.constraint_name
   FROM user_constraints c, user_tables t
   WHERE c.table_name = t.table_name
   AND c.status = 'ENABLED'
   AND c.owner = '&cwms_schema'
   AND c.constraint_type = 'R'
   ORDER BY c.constraint_type DESC)
  LOOP
    dbms_utility.exec_ddl_statement('alter table ' || c.owner || '.' || c.table_name || ' disable constraint ' || c.constraint_name);
  END LOOP;
  -- disable all triggers 
  FOR t IN
  (SELECT t.table_owner, t.table_name, t.trigger_name
   FROM user_triggers t
   WHERE 
   t.status = 'ENABLED'
   AND t.table_owner = '&cwms_schema'
   )
  LOOP
    dbms_utility.exec_ddl_statement('alter trigger ' ||  t.trigger_name || ' disable'); 
  END LOOP;

   begin
   execute immediate 'create or replace directory EXPDP_DIR as ''&cwms_dir''';
   h1 :=
      DBMS_DATAPUMP.OPEN ('IMPORT',
                          'FULL',
			   NULL,
			   'CWMS_IMPORT'
                          );
   DBMS_DATAPUMP.ADD_FILE (h1, 'cwms_at_data.dmp', 'EXPDP_DIR');
   DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','TRUNCATE');
   DBMS_DATAPUMP.START_JOB (h1);

    exception 
	when others then
	if sqlcode = dbms_datapump.success_with_info_num
        then
          dbms_output.put_line('Data Pump job started with info available:');
          dbms_datapump.get_status(h1,
                                   dbms_datapump.ku$_status_job_error,0,
                                   job_state,sts);
          if (bitand(sts.mask,dbms_datapump.ku$_status_job_error) != 0)
          then
            le := sts.error;
            if le is not null
            then
              ind := le.FIRST;
              while ind is not null loop
                dbms_output.put_line(le(ind).LogText);
                ind := le.NEXT(ind);
              end loop;
            end if;
          end if;
        else
          raise;
        end if;
    end;

   -- Specify a single dump file for the job (using the handle just returned)
   -- and a directory object, which must already be defined and accessible
   -- to the user running this procedure.

  


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

   CLEANUP();
 
EXCEPTION
   WHEN OTHERS
   THEN
   
      DBMS_OUTPUT.put_line (SQLERRM);
      dbms_output.put_line( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      DBMS_DATAPUMP.detach (h1);
      CLEANUP();
      RAISE;
END ;

/

connect sys/&sys_passwd@&inst as sysdba

exec  utl_recomp.recomp_serial('&cwms_schema');

/
exit 0

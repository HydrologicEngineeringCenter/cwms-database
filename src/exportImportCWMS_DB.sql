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
accept ccp_passwd  char prompt 'Enter the password for CCP   : '
set echo &echo_state

spool exportImportCWMS_DB.log
--
-- log on as sysdba
--
whenever sqlerror exit sql.sqlcode 
connect sys/&sys_passwd@&inst as sysdba
set serveroutput on
select sysdate from dual;

spool exportImportCWMS_DB.log

/* Formatted on 5/18/2012 10:19:09 AM (QP5 v5.163.1008.3004) */
DECLARE
   PROCEDURE REMOVE_CWMS_Q_SUBSCRIBERS
   IS
      l_queue_name   VARCHAR2 (32);
   BEGIN
      FOR rec1
         IN (SELECT name
               FROM dba_queues
              WHERE     owner = UPPER ('&CWMS_SCHEMA')
                    AND queue_type IN ('NORMAL_QUEUE')
                    AND name LIKE '%_TS_STORED')
      LOOP
         FOR rec2
            IN (SELECT consumer_name
                  FROM dba_queue_subscribers
                 WHERE owner = UPPER ('&CWMS_SCHEMA')
                       AND queue_name = rec1.name)
         LOOP
            l_queue_name := '&CWMS_SCHEMA..' || rec1.name;
            DBMS_OUTPUT.put_line (
                  'Removing subscriber '
               || rec2.consumer_name
               || 'For Q '
               || l_queue_name);
            DBMS_AQADM.remove_subscriber (
               l_queue_name,
               sys.AQ$_AGENT (rec2.consumer_name, l_queue_name, 0));
         END LOOP;
      END LOOP;
   END;

   PROCEDURE ADD_DATAFILE_NAMES (p_h IN NUMBER)
   IS
      l_ft              UTL_FILE.file_type;
      l_datafile_name   VARCHAR2 (1028);
   BEGIN
      l_ft := UTL_FILE.fopen ('EXPDP_DIR', 'datafile_define.sql', 'r');

      WHILE TRUE
      LOOP
         BEGIN
            UTL_FILE.GET_LINE (l_ft, l_datafile_name);
            DBMS_OUTPUT.PUT_LINE ('data file: ' || l_datafile_name);
            DBMS_DATAPUMP.SET_PARAMETER (p_h,
                                         'TABLESPACE_DATAFILE',
                                         l_datafile_name);
         EXCEPTION
            WHEN OTHERS
            THEN
               UTL_FILE.fclose (l_ft);
               RETURN;
         END;
      END LOOP;
   END;

   PROCEDURE DROP_ALL_JOBS
   IS
   BEGIN
      FOR c IN (SELECT owner, job_name
                  FROM dba_scheduler_jobs
                 WHERE owner = '&cwms_schema' OR owner = 'CCP')
      LOOP
         DBMS_OUTPUT.PUT_LINE (c.job_name);
         DBMS_SCHEDULER.drop_job (c.owner || '.' || c.job_name, TRUE);
      END LOOP;
   END;

   PROCEDURE WRITE_DATAFILE
   IS
      l_ft   UTL_FILE.file_type;
   BEGIN
      BEGIN
         UTL_FILE.fremove ('EXPDP_DIR', 'datafile_define.sql');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
      END;

      l_ft := UTL_FILE.fopen ('EXPDP_DIR', 'datafile_define.sql', 'w');

      FOR C IN (SELECT file_name
                  FROM dba_data_files
                 WHERE tablespace_name = 'CWMS_20_TSV')
      LOOP
         UTL_FILE.put_line (l_ft, c.file_name);
      END LOOP;

      UTL_FILE.fclose (l_ft);
   END WRITE_DATAFILE;

   PROCEDURE RENAME_BACKUP_FILE (p_fname IN VARCHAR2)
   IS
   BEGIN
      BEGIN
         UTL_FILE.FREMOVE ('EXPDP_DIR', p_fname || '_bak.dmp');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
            DBMS_OUTPUT.PUT_LINE (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;

      BEGIN
         UTL_FILE.FRENAME ('EXPDP_DIR',
                           p_fname || '.dmp',
                           'EXPDP_DIR',
                           p_fname || '_bak.dmp');
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (SQLERRM);
            DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END;
   END RENAME_BACKUP_FILE;

   PROCEDURE TOGGLE_FK_CONSTRAINTS (p_flag1         IN VARCHAR2,
                                    p_flag2         IN VARCHAR2,
                                    p_include_tsv   IN BOOLEAN DEFAULT FALSE)
   IS
      l_query             VARCHAR2 (512);
      l_owner             VARCHAR2 (32);
      l_table_name        VARCHAR2 (64);
      l_constraint_name   VARCHAR2 (64);
      l_cursor            SYS_REFCURSOR;
   BEGIN
      l_query :=
            'SELECT c.owner, c.table_name, c.constraint_name
                 FROM dba_constraints c, dba_tables t
                WHERE     c.table_name = t.table_name
                      AND c.status = '''
         || p_flag1
         || ''' AND c.owner = ''&cwms_schema''
                      AND c.constraint_type = ''R''';

      IF (p_include_tsv)
      THEN
         l_query :=
            l_query
            || ' AND c.table_name not in (select table_name from &cwms_schema..AT_TS_TABLE_PROPERTIES)';
      END IF;

      OPEN l_cursor FOR l_query;


      LOOP
         FETCH l_cursor
         INTO l_owner, l_table_name, l_constraint_name;

         EXIT WHEN l_cursor%NOTFOUND;
         DBMS_UTILITY.exec_ddl_statement (
               'alter table '
            || l_owner
            || '.'
            || l_table_name
            || ' '
            || p_flag2
            || ' constraint '
            || l_constraint_name);
      END LOOP;
   END TOGGLE_FK_CONSTRAINTS;

   PROCEDURE TOGGLE_TRIGGERS (p_flag1 VARCHAR2, p_flag2 VARCHAR2)
   IS
   BEGIN
      FOR t IN (SELECT t.table_owner, t.table_name, t.trigger_name
                  FROM dba_triggers t
                 WHERE t.status = p_flag1 AND t.table_owner = '&cwms_schema')
      LOOP
         DBMS_UTILITY.exec_ddl_statement (
               'alter trigger '
            || t.table_owner
            || '.'
            || t.trigger_name
            || ' '
            || p_flag2);
      END LOOP;
   END;



   FUNCTION CHECK_STATUS (p_handle IN NUMBER)
      RETURN VARCHAR2
   IS
      l_ind            NUMBER;
      l_percent_done   NUMBER;                   -- Percentage of job complete
      l_job_state      VARCHAR2 (30);            -- To keep track of job state
      l_le             ku$_LogEntry;             -- For WIP and error messages
      l_js             ku$_JobStatus;        -- The job status from get_status
      l_jd             ku$_JobDesc;     -- The job description from get_status
      l_sts            ku$_Status; -- The status object returned by get_status
   BEGIN
      l_percent_done := 0;
      l_job_state := 'UNDEFINED';

      WHILE (l_job_state != 'COMPLETED') AND (l_job_state != 'STOPPED')
      LOOP
         DBMS_DATAPUMP.get_status (
            p_handle,
              DBMS_DATAPUMP.ku$_status_job_error
            + DBMS_DATAPUMP.ku$_status_job_status
            + DBMS_DATAPUMP.ku$_status_wip,
            -1,
            l_job_state,
            l_sts);
         l_js := l_sts.job_status;

         -- If the percentage done changed, display the new value.

         IF l_js.percent_done != l_percent_done
         THEN
            DBMS_OUTPUT.put_line (
               '*** Job percent done = ' || TO_CHAR (l_js.percent_done));
            l_percent_done := l_js.percent_done;
         END IF;

         -- If any work-in-progress (WIP) or error messages were received for the job,
         -- display them.

         IF (BITAND (l_sts.mask, DBMS_DATAPUMP.ku$_status_wip) != 0)
         THEN
            l_le := l_sts.wip;
         ELSE
            IF (BITAND (l_sts.mask, DBMS_DATAPUMP.ku$_status_job_error) != 0)
            THEN
               l_le := l_sts.error;
            ELSE
               l_le := NULL;
            END IF;
         END IF;

         IF l_le IS NOT NULL
         THEN
            l_ind := l_le.FIRST;

            WHILE l_ind IS NOT NULL
            LOOP
               DBMS_OUTPUT.put_line (l_le (l_ind).LogText);
               l_ind := l_le.NEXT (l_ind);
            END LOOP;
         END IF;
      END LOOP;

      RETURN l_job_state;
   END CHECK_STATUS;

   PROCEDURE IMPORT_SEQUENCE
   IS
      l_handle              NUMBER;
      l_data_export_state   VARCHAR2 (64);
   BEGIN
      FOR rec IN (SELECT sequence_name
                    FROM all_sequences
                   WHERE sequence_name LIKE 'CWMS_SEQ%')
      LOOP
         EXECUTE IMMEDIATE
            'drop sequence &cwms_schema' || '.' || rec.sequence_name;
      END LOOP;

      l_handle :=
         DBMS_DATAPUMP.OPEN ('IMPORT',
                             'SCHEMA',
                             NULL,
                             NULL);
      DBMS_DATAPUMP.ADD_FILE (l_handle, 'cwms_seq_data.dmp', 'EXPDP_DIR');
      DBMS_DATAPUMP.START_JOB (l_handle);

      l_data_export_state := CHECK_STATUS (l_handle);
      -- Indicate that the job finished and detach from it.

      DBMS_OUTPUT.put_line ('Sequence import job has completed');
      DBMS_OUTPUT.put_line (
         'Final job state (Sequence import) = ' || l_data_export_state);
      DBMS_DATAPUMP.detach (l_handle);
   END;

   PROCEDURE EXPORT_SEQUENCE
   IS
      l_handle              NUMBER;
      l_data_export_state   VARCHAR2 (64);
      l_export_exception    EXCEPTION;
   BEGIN
      RENAME_BACKUP_FILE ('cwms_seq_data');
      l_handle :=
         DBMS_DATAPUMP.OPEN ('EXPORT',
                             'SCHEMA',
                             NULL,
                             NULL,
                             'LATEST');


      DBMS_DATAPUMP.ADD_FILE (l_handle, 'cwms_seq_data.dmp', 'EXPDP_DIR');

      DBMS_DATAPUMP.METADATA_FILTER (l_handle,
                                     'SCHEMA_EXPR',
                                     'IN (''&cwms_schema'')');

      DBMS_DATAPUMP.METADATA_FILTER (l_handle,
                                     'INCLUDE_PATH_EXPR',
                                     'IN (''SEQUENCE'')');

      DBMS_DATAPUMP.METADATA_FILTER (
         l_handle,
         'NAME_EXPR',
         'IN (SELECT  sequence_name from dba_sequences where sequence_owner = ''&cwms_schema'' and sequence_name like ''CWMS_SEQ%'' )',
         'SEQUENCE');


      DBMS_DATAPUMP.START_JOB (l_handle);
      l_data_export_state := CHECK_STATUS (l_handle);
      DBMS_OUTPUT.put_line ('Sequence export Job has completed');
      DBMS_OUTPUT.put_line (
         'Final job state(sequence export) = ' || l_data_export_state);
      DBMS_DATAPUMP.detach (l_handle);

      IF l_data_export_state != 'COMPLETED'
      THEN
         RAISE l_export_exception;
      END IF;
   END;

   PROCEDURE CREATE_USER (p_username          IN VARCHAR2,
                          p_tablespace_name   IN VARCHAR2)
   IS
   BEGIN
      EXECUTE IMMEDIATE
            'CREATE  TABLESPACE '
         || p_tablespace_name
         || ' DATAFILE AUTOEXTEND  ON';

      EXECUTE IMMEDIATE
            'CREATE USER '
         || p_username
         || ' IDENTIFIED BY TWOHOT4U DEFAULT TABLESPACE '
         || p_tablespace_name
         || ' QUOTA UNLIMITED ON CWMS_20_AT_DATA_BAK';
   END;

   PROCEDURE DROP_USER (p_username          IN VARCHAR2,
                        p_tablespace_name   IN VARCHAR2)
   IS
   BEGIN
      EXECUTE IMMEDIATE 'DROP USER ' || p_username || ' CASCADE';

      EXECUTE IMMEDIATE 'DROP  TABLESPACE ' || p_tablespace_name;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (SQLERRM);
         DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
   END;

   FUNCTION GET_COL_LIST (p_table_name   IN VARCHAR2,
                          p_schema       IN VARCHAR2,
                          p_isSelect     IN BOOLEAN := FALSE)
      RETURN VARCHAR2
   IS
      l_return        VARCHAR2 (2048);
      l_query         VARCHAR2 (512);
      l_cur           SYS_REFCURSOR;
      l_column_name   VARCHAR2 (64);
   BEGIN
      l_query :=
            'SELECT column_name
                  FROM dba_tab_columns
                 WHERE table_name = '''
         || p_table_name
         || ''' AND owner = '''
         || p_schema
         || '''';

      IF p_isSelect
      THEN
         l_query :=
            l_query
            || ' AND DATA_TYPE != ''CLOB'' AND DATA_TYPE != ''SDO_GEOMETRY'' AND DATA_TYPE != ''BLOB'' AND DATA_TYPE != ''BFILE'' AND DATA_TYPE != ''VARRAY''';
      END IF;

      --DBMS_OUTPUT.PUT_LINE (l_query);

      OPEN l_cur FOR l_query;

      LOOP
         FETCH l_cur INTO l_column_name;

         EXIT WHEN l_cur%NOTFOUND;

         IF (l_return IS NULL)
         THEN
            l_return := l_column_name;
         ELSE
            l_return := l_return || ',' || l_column_name;
         END IF;
      END LOOP;

      RETURN l_return;
   END;

   PROCEDURE COPY_BACK_TABLES (p_fromUser VARCHAR2, p_toUser VARCHAR2)
   IS
      l_insert_col   VARCHAR2 (2048);
      l_select_col   VARCHAR2 (2048);
      l_query        VARCHAR2 (256);
      l_copycmd      VARCHAR2 (4096);
      l_cur          SYS_REFCURSOR;
      l_tablename    VARCHAR (64);
   BEGIN
      l_query :=
         'select d1.table_name from dba_tables d1, dba_tables d2 where d1.table_name = d2.table_name and d1.owner = ''&CWMS_SCHEMA'' and d2.owner = ''CWMS_20_BAK''';

      OPEN l_cur FOR l_query;

      LOOP
         FETCH l_cur INTO l_tablename;

         EXIT WHEN l_cur%NOTFOUND;
         l_insert_col := GET_COL_LIST (l_tablename, p_fromUser);
         l_select_col := GET_COL_LIST (l_tablename, p_fromUser, TRUE);
         l_copycmd :=
               'INSERT INTO '
            || p_toUser
            || '.'
            || l_tablename
            || ' ( '
            || l_insert_col
            || ' ) SELECT '
            || l_insert_col
            || ' FROM '
            || p_fromUser
            || '.'
            || l_tablename
            || ' WHERE ( '
            || l_select_col
            || ') NOT IN ( SELECT '
            || l_select_col
            || ' FROM '
            || p_toUser
            || '.'
            || l_tablename
            || ')';

         --DBMS_OUTPUT.PUT_LINE (l_copycmd);

         BEGIN
            EXECUTE IMMEDIATE l_copycmd;

            IF SQL%ROWCOUNT > 0
            THEN
               DBMS_OUTPUT.PUT_LINE (
                  'Inserted ' || SQL%ROWCOUNT || ' Rows in ' || l_tablename);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
	       DBMS_OUTPUT.put_line ('Error inserting into ' || l_tablename || ' ' || l_copycmd);
               DBMS_OUTPUT.put_line (SQLERRM);
               DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE COPY_TABLES (p_fromUser       VARCHAR2,
                          p_toUser         VARCHAR2,
                          p_whereClause    VARCHAR2)
   IS
      l_query       VARCHAR2 (256);
      l_createcmd   VARCHAR2 (256);
      l_copycmd     VARCHAR (2048);
      l_tablename   VARCHAR2 (64);
      l_cur         SYS_REFCURSOR;
   BEGIN
      l_query :=
            'select table_name from dba_tables where owner = '''
         || p_fromUser
         || '''';

      IF (p_whereClause IS NOT NULL)
      THEN
         l_query := l_query || ' AND ' || p_whereClause;
      END IF;

      DBMS_OUTPUT.PUT_LINE (l_query);

      OPEN l_cur FOR l_query;

      LOOP
         FETCH l_cur INTO l_tablename;

         EXIT WHEN l_cur%NOTFOUND;
         l_createcmd :=
               'CREATE TABLE '
            || p_toUser
            || '.'
            || l_tablename
            || ' AS SELECT * FROM '
            || p_fromUser
            || '.'
            || l_tablename;

         --DBMS_OUTPUT.PUT_LINE (l_createcmd);

         EXECUTE IMMEDIATE l_createcmd;
      END LOOP;

      CLOSE l_cur;

      COMMIT;
   END COPY_TABLES;

   PROCEDURE BACKUP_CWMS_ROLES
   IS
      l_lastval   NUMBER;
      l_cmd       VARCHAR2 (256);
   BEGIN
      EXECUTE IMMEDIATE
         'CREATE TABLE CWMS_20_BAK.CWMS_ROLES_BAK (grantee varchar2(30), granted_role varchar2(30)) TABLESPACE CWMS_20_AT_DATA_BAK';

      l_cmd :=
         'Insert into CWMS_20_BAK.CWMS_ROLES_BAK(grantee,granted_role) select grantee,granted_role from DBA_ROLE_PRIVS where grantee not like ''%HECTEST%'' and grantee not like ''%CWMSPD%%'' and (granted_role = ''CWMS_USER'' or granted_role = ''CWMS_DBX_ROLE'')';
      DBMS_OUTPUT.put_line (l_cmd);

      EXECUTE IMMEDIATE l_cmd;

      COMMIT;
   END BACKUP_CWMS_ROLES;

   PROCEDURE RECREATE_CWMS_ROLES
   IS
      l_cmd            VARCHAR2 (128);
      l_select         VARCHAR2 (128);
      l_cur            SYS_REFCURSOR;
      l_grantee        VARCHAR (30);
      l_granted_role   VARCHAR (30);
   BEGIN
      l_select :=
         'SELECT grantee, granted_role FROM  CWMS_20_BAK.CWMS_ROLES_BAK';

      OPEN l_cur FOR l_select;

      LOOP
         FETCH l_cur
         INTO l_grantee, l_granted_role;

         EXIT WHEN l_cur%NOTFOUND;
         l_cmd := 'Grant ' || l_granted_role || ' to ' || l_grantee;
         DBMS_OUTPUT.PUT_LINE (l_cmd);

         EXECUTE IMMEDIATE l_cmd;
      END LOOP;

      COMMIT;
   END RECREATE_CWMS_ROLES;

   PROCEDURE BACKUP_CWMS_SEQ
   IS
      l_lastval   NUMBER;
      l_cmd       VARCHAR2 (128);
   BEGIN
      EXECUTE IMMEDIATE
         'CREATE TABLE CWMS_20_BAK.CWMS_SEQ_BAK (last_val NUMBER) TABLESPACE CWMS_20_AT_DATA_BAK';

      SELECT last_number
        INTO l_lastval
        FROM dba_sequences
       WHERE sequence_owner = '&cwms_schema' AND sequence_name = 'CWMS_SEQ';

      l_cmd :=
            'Insert into CWMS_20_BAK.CWMS_SEQ_BAK(last_val) values('
         || l_lastval
         || ')';
      DBMS_OUTPUT.put_line (l_cmd);

      EXECUTE IMMEDIATE l_cmd;

      COMMIT;
   END BACKUP_CWMS_SEQ;

   PROCEDURE BACKUP_TSB_ENTRIES
   IS
   BEGIN
      EXECUTE IMMEDIATE
         'CREATE TABLE CWMS_20_BAK.CWMS_TSV_BAK (TABLE_NAME VARCHAR2(64)) TABLESPACE CWMS_20_AT_DATA_BAK';

      FOR c
         IN (SELECT table_name object_name, owner
               FROM dba_tables
              WHERE tablespace_name = 'CWMS_20_TSV'
             UNION
             SELECT table_name object_name, owner
               FROM dba_indexes
              WHERE tablespace_name = 'CWMS_20_TSV'
                    AND index_type LIKE 'IOT%')
      LOOP
         EXECUTE IMMEDIATE
               'INSERT INTO CWMS_20_BAK.CWMS_TSV_BAK (TABLE_NAME) VALUES ('''
            || c.object_name
            || ''')';
      END LOOP;
   END;

   PROCEDURE EXPORT_TSV (p_dump_file   IN VARCHAR2,
                         p_parallel    IN INTEGER DEFAULT 9)
   IS
      l_handle              NUMBER;
      l_data_export_state   VARCHAR2 (64);
      l_dump_file           VARCHAR2 (64);
      l_parallel            INTEGER;
      l_export_exception    EXCEPTION;
   BEGIN
      IF (p_parallel > 9)
      THEN
         l_parallel := 9;
      ELSIF (p_parallel < 1)
      THEN
         l_parallel := 1;
      ELSE
         l_parallel := p_parallel;
      END IF;

      IF (l_parallel > 1)
      THEN
         FOR num IN 1 .. 9
         LOOP
            l_dump_file := p_dump_file || '0' || num;
            DBMS_OUTPUT.PUT_LINE (l_dump_file);
            RENAME_BACKUP_FILE (l_dump_file);
         END LOOP;
      ELSE
         RENAME_BACKUP_FILE (p_dump_file);
      END IF;


      l_handle :=
         DBMS_DATAPUMP.OPEN ('EXPORT',
                             'TABLE',
                             NULL,
                             NULL,
                             'LATEST');
      DBMS_OUTPUT.PUT_LINE (l_parallel);

      IF (l_parallel > 1)
      THEN
         DBMS_DATAPUMP.ADD_FILE (l_handle, p_dump_file || '%U', 'EXPDP_DIR');
      ELSE
         DBMS_DATAPUMP.ADD_FILE (l_handle, p_dump_file, 'EXPDP_DIR');
      END IF;

      DBMS_DATAPUMP.METADATA_FILTER (l_handle,
                                     'SCHEMA_EXPR',
                                     'IN (''&cwms_schema'')');



      DBMS_DATAPUMP.METADATA_FILTER (
         l_handle,
         'NAME_EXPR',
         'IN (SELECT  table_name from dba_tables where owner = ''&cwms_schema'' and table_name like ''AT_TSV%'' )',
         'TABLE');
      DBMS_DATAPUMP.SET_PARAMETER (l_handle, 'INCLUDE_METADATA', 0);
      DBMS_DATAPUMP.SET_PARALLEL (l_handle, l_parallel);
      DBMS_DATAPUMP.START_JOB (l_handle);
      l_data_export_state := CHECK_STATUS (l_handle);
      DBMS_OUTPUT.put_line ('Sequence export Job has completed');
      DBMS_OUTPUT.put_line (
         'Final job state(sequence export) = ' || l_data_export_state);

      DBMS_DATAPUMP.detach (l_handle);

      IF l_data_export_state != 'COMPLETED'
      THEN
         RAISE l_export_exception;
      END IF;
   END;


   PROCEDURE EXPORT_CWMS_TSV_TB
   IS
      l_handle              NUMBER;                    -- Data Pump job handle

      l_data_export_state   VARCHAR2 (30);            -- Status of export jobs
      l_data_filename       VARCHAR2 (1024);
      l_export_exception    EXCEPTION;
   BEGIN
      --EXECUTE IMMEDIATE 'ALTER TABLE ' || '&CWMS_SCHEMA' || '.CWMS_DATA_QUALITY MOVE TABLESPACE CWMS_20_TSV';
      --EXECUTE IMMEDIATE 'ALTER TABLE ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC MOVE TABLESPACE CWMS_20_TSV';
      --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC_PK REBUILD TABLESPACE CWMS_20_TSV';
      --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.AT_CWMS_TS_SPEC_UI REBUILD TABLESPACE CWMS_20_TSV';
      --EXECUTE IMMEDIATE 'ALTER INDEX ' || '&CWMS_SCHEMA' || '.CWMS_DATA_QUALITY_PK REBUILD TABLESPACE CWMS_20_TSV';
      WRITE_DATAFILE;

      BACKUP_TSB_ENTRIES;

      RENAME_BACKUP_FILE ('cwms_at_tsv');

      EXECUTE IMMEDIATE 'ALTER TABLESPACE CWMS_20_TSV read only';

      l_handle :=
         DBMS_DATAPUMP.OPEN ('EXPORT',
                             'TRANSPORTABLE',
                             NULL,
                             NULL);

      DBMS_DATAPUMP.ADD_FILE (l_handle, 'cwms_at_tsv.dmp', 'EXPDP_DIR');
      DBMS_DATAPUMP.METADATA_FILTER (l_handle,
                                     'TABLESPACE_EXPR',
                                     'IN (''CWMS_20_TSV'')');
      DBMS_DATAPUMP.START_JOB (l_handle);
      l_data_export_state := CHECK_STATUS (l_handle);
      DBMS_OUTPUT.put_line ('Tablespace export Job has completed');
      DBMS_OUTPUT.put_line (
         'Final job state(Tablespace) = ' || l_data_export_state);
      DBMS_DATAPUMP.detach (l_handle);

      EXECUTE IMMEDIATE
         'drop tablespace CWMS_20_TSV including contents keep datafiles cascade constraints';

      EXECUTE IMMEDIATE
         'create  tablespace CWMS_20_TSV datafile autoextend on';

      IF l_data_export_state != 'COMPLETED'
      THEN
         RAISE l_export_exception;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (SQLERRM);
         DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         DBMS_DATAPUMP.detach (l_handle);
         --ENABLE_FK_CONSTRAINTS;
         RAISE;
   END EXPORT_CWMS_TSV_TB;

   PROCEDURE EXPORT_CWMS_AT_DATA
   IS
   BEGIN
      TOGGLE_FK_CONSTRAINTS ('ENABLED', 'DISABLE');
      REMOVE_CWMS_Q_SUBSCRIBERS;
      DROP_USER ('CWMS_20_BAK', 'CWMS_20_AT_DATA_BAK');
      CREATE_USER ('CWMS_20_BAK', 'CWMS_20_AT_DATA_BAK');
      BACKUP_CWMS_ROLES;
      BACKUP_CWMS_SEQ;
      COPY_TABLES (
         '&cwms_schema',
         'CWMS_20_BAK',
         'TABLE_NAME LIKE ''AT_%'' AND TABLE_NAME NOT LIKE ''AT_TSV%'' AND TABLE_NAME NOT LIKE ''AT_TS_MSG_ARCHIVE_%'' AND TABLE_NAME NOT LIKE ''AT_LOG_MESSAGE%''');
      EXPORT_SEQUENCE;
      --EXPORT_TSV ('cwms_tsv_dump');
      EXPORT_CWMS_TSV_TB;
   END;

   PROCEDURE EXPORT_CWMS
   IS
   BEGIN
      EXECUTE IMMEDIATE
         'Update ' || '&CWMS_SCHEMA'
         || '.AT_PARAMETER Set SUB_PARAMETER_DESC = ''Percent'' WHERE PARAMETER_CODE = 1 AND DB_OFFICE_CODE = 53 AND BASE_PARAMETER_CODE = 1';

      COMMIT;
      DROP_ALL_JOBS;

      EXPORT_CWMS_AT_DATA;
   END;

   PROCEDURE CREATE_BAK_TB
   IS
   BEGIN
      EXECUTE IMMEDIATE
         'create  tablespace CWMS_20_TSV_BAK datafile autoextend on';

      EXECUTE IMMEDIATE
         'ALTER USER &cwms_schema  QUOTA UNLIMITED ON CWMS_20_TSV_BAK';
   END;

   PROCEDURE DROP_BAK_TB
   IS
   BEGIN
      EXECUTE IMMEDIATE 'drop  tablespace CWMS_20_TSV_BAK including contents';
   END;


   PROCEDURE MOVE_TSV_OBJECTS (p_fromTb        VARCHAR2,
                               p_toTb          VARCHAR2,
                               where_clause    VARCHAR2)
   IS
      l_query        VARCHAR2 (1024);
      l_cur          SYS_REFCURSOR;
      l_table_name   VARCHAR2 (64);
      l_owner        VARCHAR2 (64);
   BEGIN
      l_query :=
            'SELECT table_name object_name, owner
               FROM dba_tables
              WHERE tablespace_name = '''
         || p_fromTb
         || ''''
         || where_clause
         || ' UNION
             SELECT table_name object_name, owner
               FROM dba_indexes
              WHERE tablespace_name = '''
         || p_fromTb
         || ''' AND index_type LIKE ''IOT%'''
         || where_clause;
      DBMS_OUTPUT.PUT_LINE (l_query);

      OPEN l_cur FOR l_query;

      LOOP
         FETCH l_cur
         INTO l_table_name, l_owner;

         EXIT WHEN l_cur%NOTFOUND;

         EXECUTE IMMEDIATE
               'Alter Table '
            || l_owner
            || '.'
            || l_table_name
            || ' move tablespace '
            || p_toTb;
      END LOOP;

      l_query :=
            'SELECT index_name object_name, owner
               FROM dba_indexes
              WHERE tablespace_name = '''
         || p_fromTb
         || '''AND index_type NOT LIKE ''IOT%'''
         || where_clause;
      DBMS_OUTPUT.PUT_LINE (l_query);

      OPEN l_cur FOR l_query;

      LOOP
         FETCH l_cur
         INTO l_table_name, l_owner;

         EXIT WHEN l_cur%NOTFOUND;

         EXECUTE IMMEDIATE
               'Alter Index '
            || l_owner
            || '.'
            || l_table_name
            || '  rebuild tablespace '
            || p_toTb;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (SQLERRM);
         DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
   END;

   PROCEDURE IMPORT_TSV (p_dump_file VARCHAR2, p_parallel INTEGER DEFAULT 9)
   IS
      l_handle              NUMBER;
      l_data_import_state   VARCHAR2 (30);
      l_parallel            INTEGER;
      l_import_exception    EXCEPTION;
   BEGIN
      IF (p_parallel > 9)
      THEN
         l_parallel := 9;
      ELSIF (p_parallel < 1)
      THEN
         l_parallel := 1;
      ELSE
         l_parallel := p_parallel;
      END IF;

      l_handle :=
         DBMS_DATAPUMP.OPEN ('IMPORT',
                             'TABLE',
                             NULL,
                             NULL);

      IF (l_parallel > 1)
      THEN
         DBMS_DATAPUMP.ADD_FILE (l_handle, p_dump_file || '%U', 'EXPDP_DIR');
      ELSE
         DBMS_DATAPUMP.ADD_FILE (l_handle, p_dump_file, 'EXPDP_DIR');
      END IF;

      DBMS_DATAPUMP.START_JOB (l_handle);
      l_data_import_state := CHECK_STATUS (l_handle);

      DBMS_OUTPUT.PUT_LINE (
         'Import state(Tablespace import):' || l_data_import_state);
      DBMS_DATAPUMP.detach (l_handle);

      IF l_data_import_state != 'COMPLETED'
      THEN
         RAISE l_import_exception;
      END IF;
   END;

   PROCEDURE IMPORT_TSV_TB
   IS
      l_handle              NUMBER;
      l_data_import_state   VARCHAR2 (30);
      l_import_exception    EXCEPTION;
   BEGIN
      CREATE_BAK_TB;
      MOVE_TSV_OBJECTS (
         'CWMS_20_TSV',
         'CWMS_20_TSV_BAK',
         ' AND  TABLE_NAME NOT IN (SELECT TABLE_NAME FROM CWMS_20_BAK.CWMS_TSV_BAK)');

      EXECUTE IMMEDIATE
         'drop tablespace cwms_20_tsv including contents cascade constraints';

      l_handle :=
         DBMS_DATAPUMP.OPEN ('IMPORT',
                             'TRANSPORTABLE',
                             NULL,
                             NULL);
      DBMS_DATAPUMP.ADD_FILE (l_handle, 'cwms_at_tsv.dmp', 'EXPDP_DIR');
      ADD_DATAFILE_NAMES (l_handle);
      DBMS_DATAPUMP.START_JOB (l_handle);
      l_data_import_state := CHECK_STATUS (l_handle);

      DBMS_OUTPUT.PUT_LINE (
         'Import state(Tablespace import):' || l_data_import_state);
      DBMS_DATAPUMP.detach (l_handle);

      EXECUTE IMMEDIATE 'ALTER TABLESPACE CWMS_20_TSV read write';

      MOVE_TSV_OBJECTS ('CWMS_20_TSV_BAK', 'CWMS_20_TSV', '');
      DROP_BAK_TB;

      IF l_data_import_state != 'COMPLETED'
      THEN
         RAISE l_import_exception;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (SQLERRM);
         DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         DBMS_DATAPUMP.detach (l_handle);
         --ENABLE_FK_CONSTRAINTS;
         RAISE;
   END;

   PROCEDURE RESTORE_CCP_PERMISSIONS
   IS
      l_user_name   VARCHAR2 (5) := NULL;
   BEGIN
      BEGIN
         SELECT username
           INTO l_user_name
           FROM ALL_USERS
          WHERE username = 'CCP';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RETURN;
      END;


      EXECUTE IMMEDIATE 'GRANT CWMS_USER TO CCP';

      EXECUTE IMMEDIATE
         'GRANT SELECT ON &CWMS_SCHEMA..AV_LOC TO CCP WITH GRANT OPTION';

      EXECUTE IMMEDIATE 'GRANT SELECT ON &CWMS_SCHEMA..AV_TSV TO CCP';

      EXECUTE IMMEDIATE 'GRANT EXECUTE ON &CWMS_SCHEMA..CWMS_MSG TO CCP';

      EXECUTE IMMEDIATE 'GRANT EXECUTE ON &CWMS_SCHEMA..CWMS_TS TO CCP';

      EXECUTE IMMEDIATE 'GRANT EXECUTE ON &CWMS_SCHEMA..CWMS_UTIL TO CCP';

      EXECUTE IMMEDIATE
         'GRANT EXECUTE ON &CWMS_SCHEMA..DATE_TABLE_TYPE TO CCP';

      EXECUTE IMMEDIATE
         'GRANT EXECUTE ON &CWMS_SCHEMA..JMS_MAP_MSG_TAB_T TO CCP';

      EXECUTE IMMEDIATE 'GRANT CCP_USERS TO CWMS_USER';

      UTL_RECOMP.RECOMP_SERIAL ('CCP');
   END;

   PROCEDURE IMPORT_CWMS
   IS
   BEGIN
      DROP_ALL_JOBS;
      TOGGLE_FK_CONSTRAINTS ('ENABLED', 'DISABLE');
      TOGGLE_TRIGGERS ('ENABLED', 'DISABLE');
      COPY_BACK_TABLES ('CWMS_20_BAK', 'CWMS_20');

      IMPORT_SEQUENCE;
      --IMPORT_TSV ('cwms_tsv_dump');
      IMPORT_TSV_TB;


      EXECUTE IMMEDIATE
         'BEGIN &CWMS_SCHEMA..CWMS_TS_ID.refresh_at_cwms_ts_id; END;';

      TOGGLE_FK_CONSTRAINTS ('DISABLED', 'ENABLE');
      TOGGLE_TRIGGERS ('DISABLED', 'ENABLE');
      UTL_RECOMP.RECOMP_SERIAL ('&CWMS_SCHEMA');
      RESTORE_CCP_PERMISSIONS;
      RECREATE_CWMS_ROLES; 
      COMMIT;
   END;

   PROCEDURE EXPORT_SCHEMA (p_schema_name   IN VARCHAR2,
                            p_dump_file     IN VARCHAR2,
                            p_parallel      IN INTEGER DEFAULT 9)
   IS
      l_handle              NUMBER;
      l_data_export_state   VARCHAR2 (64);
      l_dump_file           VARCHAR2 (64);
      l_parallel            INTEGER;
   BEGIN
      IF (p_parallel > 9)
      THEN
         l_parallel := 9;
      ELSIF (p_parallel < 1)
      THEN
         l_parallel := 1;
      ELSE
         l_parallel := p_parallel;
      END IF;

      IF (l_parallel > 1)
      THEN
         FOR num IN 1 .. 9
         LOOP
            l_dump_file := p_dump_file || '0' || num;
            DBMS_OUTPUT.PUT_LINE (l_dump_file);
            RENAME_BACKUP_FILE (l_dump_file);
         END LOOP;
      ELSE
         RENAME_BACKUP_FILE (p_dump_file);
      END IF;


      l_handle :=
         DBMS_DATAPUMP.OPEN ('EXPORT',
                             'SCHEMA',
                             NULL,
                             NULL,
                             'LATEST');

      IF (l_parallel > 1)
      THEN
         DBMS_DATAPUMP.ADD_FILE (l_handle, p_dump_file || '%U', 'EXPDP_DIR');
      ELSE
         DBMS_DATAPUMP.ADD_FILE (l_handle, p_dump_file, 'EXPDP_DIR');
      END IF;

      DBMS_DATAPUMP.METADATA_FILTER (l_handle,
                                     'SCHEMA_EXPR',
                                     'IN (''' || p_schema_name || ''')');

      DBMS_DATAPUMP.SET_PARALLEL (l_handle, l_parallel);
      DBMS_DATAPUMP.START_JOB (l_handle);
      l_data_export_state := CHECK_STATUS (l_handle);
      DBMS_OUTPUT.put_line ('Sequence export Job has completed');
      DBMS_OUTPUT.put_line (
         'Final job state(sequence export) = ' || l_data_export_state);
      DBMS_DATAPUMP.detach (l_handle);
   END;
BEGIN
   --EXECUTE IMMEDIATE 'ALTER SYSTEM ENABLE RESTRICTED SESSION';

   EXECUTE IMMEDIATE 'create or replace directory expdp_dir as ''&cwms_dir''';

   --EXPORT_CWMS;

   --IMPORT_CWMS;

   --EXPORT_SCHEMA('&CWMS_SCHEMA','cwms_export_dump');

   --EXECUTE IMMEDIATE 'ALTER SYSTEM DISABLE RESTRICTED SESSION';
   DBMS_LOCK.SLEEP (1);
END;
/

/* UNCOMMENT FOR IMPORT
connect &cwms_schema/&cwms_passwd@&inst
exec cwms_msg.start_trim_log_job;
exec cwms_msg.start_purge_queues_job;
exec cwms_schema.cleanup_schema_version_table;
exec cwms_schema.start_check_schema_job;
exec cwms_ts.start_trim_ts_deleted_job;
exec cwms_sec.start_refresh_mv_sec_privs_job;
exec cwms_shef.start_update_shef_spec_map_job;
exec cwms_rating.start_update_mviews_job;
whenever sqlerror continue
connect ccp/&ccp_passwd@&inst
exec CWMS_CCP.START_CHECK_CALLBACK_PROC_JOB;
   UNCOMMENT FOR IMPORT */

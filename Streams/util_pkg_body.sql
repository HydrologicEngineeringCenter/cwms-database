CREATE OR REPLACE PACKAGE BODY CWMS_STR_ADM.Util
AS
   FUNCTION GET_APPLY_HANDLER_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
      l_tables (1) := g_cwms_user || '.AT_TSV_2013';
      l_tables (2) := g_cwms_user || '.AT_TSV_2014';
      l_tables (3) := g_streams_user || '.CWMS_HEARTBEAT';
      RETURN l_tables;
   END GET_APPLY_HANDLER_TABLES;

   FUNCTION GET_MERGE_TSV_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
      l_tables (1) := g_cwms_user || '.AT_TSV_2013';
      l_tables (2) := g_cwms_user || '.AT_TSV_2014';
      RETURN l_tables;
   END GET_MERGE_TSV_TABLES;

   FUNCTION GET_EDS_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
      l_tables (1) := g_cwms_user || '.AT_GEOGRAPHIC_LOCATION';
      RETURN l_tables;
   END GET_EDS_TABLES;

   FUNCTION GET_STREAMS_OBJECT_NAME (p_source_db      VARCHAR2,
                                     p_object_type    VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      CASE p_object_type
         WHEN 'CAPTURE QUEUE'
         THEN
            RETURN g_streams_user || '.' || 'CWMS_STR_CQ_' || p_source_db;
         WHEN 'CAPTURE QUEUE TABLE'
         THEN
            RETURN g_streams_user || '.' || 'CWMS_STR_CQT_' || p_source_db;
         WHEN 'APPLY QUEUE'
         THEN
            RETURN g_streams_user || '.' || 'CWMS_STR_AQ_' || p_source_db;
         WHEN 'APPLY QUEUE TABLE'
         THEN
            RETURN g_streams_user || '.' || 'CWMS_STR_AQT_' || p_source_db;
         WHEN 'CAPTURE'
         THEN
            RETURN 'CWMS_STR_CP_' || p_source_db;
         WHEN 'APPLY'
         THEN
            RETURN 'CWMS_STR_AP_' || p_source_db;
         WHEN 'PROPAGATION'
         THEN
            RETURN 'CWMS_STR_PP_' || p_source_db;
      END CASE;
   END GET_STREAMS_OBJECT_NAME;

   FUNCTION GET_CAPTURE_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'CAPTURE');
   END;

   FUNCTION GET_CAPTURE_QUEUE_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'CAPTURE QUEUE');
   END;

   FUNCTION GET_CAPTURE_QUEUE_TABLE_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'CAPTURE QUEUE TABLE');
   END;

   FUNCTION GET_APPLY_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'APPLY');
   END;

   FUNCTION GET_APPLY_QUEUE_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'APPLY QUEUE');
   END;


   FUNCTION GET_APPLY_QUEUE_TABLE_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'APPLY QUEUE TABLE');
   END;

   FUNCTION GET_PROPAGATION_NAME (p_source_db VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN GET_STREAMS_OBJECT_NAME (p_source_db, 'PROPAGATION');
   END;

   PROCEDURE CREATE_QUEUE (p_source_db VARCHAR2, p_queue_type VARCHAR2)
   IS
   BEGIN
      DBMS_STREAMS_ADM.set_up_queue (
         queue_table      => GET_STREAMS_OBJECT_NAME (
                               p_source_db,
                               p_queue_type || ' QUEUE TABLE'),
         storage_clause   => NULL,
         queue_name       => GET_STREAMS_OBJECT_NAME (
                               p_source_db,
                               p_queue_type || ' QUEUE'));
   END CREATE_QUEUE;

   FUNCTION GET_STREAMING_EDS_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
      idx        NUMBER;
   BEGIN
      idx := 1;

      FOR C IN (SELECT OWNER, SHADOW_TABLE_NAME FROM EDS_SHADOW_TABLES)
      LOOP
         l_tables (idx) := C.OWNER || '.' || C.SHADOW_TABLE_NAME;
         idx := idx + 1;
      END LOOP;

      RETURN l_tables;
   END GET_STREAMING_EDS_TABLES;

   FUNCTION GET_STREAMING_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
        SELECT owner || '.' || table_name
          BULK COLLECT INTO l_tables
          FROM dba_tables
         WHERE (owner = g_cwms_user AND table_name LIKE 'AT_%'
                AND table_name NOT IN
                       ('AT_LOG_MESSAGE',
                        'AT_LOG_MESSAGE_PROPERTIES',
                        'AT_TS_MSG_ARCHIVE_1',
                        'AT_TS_MSG_ARCHIVE_2',
                        'AT_TS_DELETED_TIMES')
                AND table_name <> 'AT_GEOGRAPHIC_LOCATION'
                AND table_name NOT IN
                       ('AT_TSV',
                        'AT_TSV_ARCHIVAL',
                        'AT_TSV_2002',
                        'AT_TSV_2003',
                        'AT_TSV_2004',
                        'AT_TSV_2005',
                        'AT_TSV_2006',
                        'AT_TSV_2007',
                        'AT_TSV_2008',
                        'AT_TSV_2009',
                        'AT_TSV_2010',
                        'AT_TSV_2011',
                        'AT_TSV_2012',
                        'AT_TSV_2015',
                        'AT_TSV_2016',
                        'AT_TSV_2017',
                        'AT_TSV_2018',
                        'AT_TSV_2019',
                        'AT_TSV_2020',
                        'AT_TSV_INF_AND_BEYOND'))
               OR (owner = g_streams_user AND TABLE_NAME = 'CWMS_HEARTBEAT')
      ORDER BY table_name;

      RETURN l_tables;
   END GET_STREAMING_TABLES;

   FUNCTION GET_COPY_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
        SELECT table_name
          BULK COLLECT INTO l_tables
          FROM dba_tables
         WHERE owner = g_cwms_user AND table_name LIKE 'AT_%'
               AND table_name NOT IN
                      ('AT_LOG_MESSAGE',
                       'AT_LOG_MESSAGE_PROPERTIES',
                       'AT_TS_MSG_ARCHIVE_1',
                       'AT_TS_MSG_ARCHIVE_2',
                       'AT_TS_DELETED_TIMES')
               AND table_name <> 'AT_GEOGRAPHIC_LOCATION'
               AND table_name NOT LIKE 'AT_TSV%'
      ORDER BY table_name;

      RETURN l_tables;
   END GET_COPY_TABLES;

   PROCEDURE START_ALL_APPLY
   IS
   BEGIN
      FOR c IN (SELECT apply_name FROM dba_apply)
      LOOP
         DBMS_OUTPUT.put_line (c.apply_name);
         DBMS_APPLY_ADM.START_APPLY (c.apply_name);
      END LOOP;
   END;

   PROCEDURE STOP_ALL_APPLY
   IS
   BEGIN
      FOR c IN (SELECT apply_name FROM dba_apply)
      LOOP
         DBMS_OUTPUT.put_line (c.apply_name);
         DBMS_APPLY_ADM.STOP_APPLY (c.apply_name);
      END LOOP;
   END;

   PROCEDURE START_HEARTBEAT_JOB (p_source_db VARCHAR2)
   IS
   BEGIN
      BEGIN
         DBMS_SCHEDULER.DROP_JOB (g_heartbeat_job_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      DBMS_SCHEDULER.CREATE_JOB (
         job_name          => g_heartbeat_job_name,
         job_type          => 'PLSQL_BLOCK',
         job_action        =>   'BEGIN util.update_heartbeat('''
                             || p_source_db
                             || '''); END;',
         start_date        => NULL,
         repeat_interval   => 'freq=secondly; interval=60',
         job_class         => 'default_job_class',
         enabled           => TRUE,
         auto_drop         => FALSE,
         comments          => 'Update hearbeat table');
   END START_HEARTBEAT_JOB;

   PROCEDURE STOP_HEARTBEAT_JOB
   IS
   BEGIN
      DBMS_SCHEDULER.drop_job (g_streams_user || '.' || g_heartbeat_job_name,
                               TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('Error dropping heartbeat job');
   END;

   PROCEDURE START_RESET_SCN_JOB
   IS
   BEGIN
      BEGIN
         DBMS_SCHEDULER.DROP_JOB (g_reset_scn_job_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      DBMS_SCHEDULER.CREATE_JOB (
         job_name          => g_reset_scn_job_name,
         job_type          => 'stored_procedure',
         job_action        => 'util.reset_scn',
         start_date        => NULL,
         repeat_interval   => 'freq=hourly; interval=12',
         job_class         => 'default_job_class',
         enabled           => TRUE,
         auto_drop         => FALSE,
         comments          => 'Reset first/start SCN so that archivelogs are not heldup');
   END START_RESET_SCN_JOB;


   PROCEDURE START_TRIM_ERRORLOG_JOB
   IS
   BEGIN
      BEGIN
         DBMS_SCHEDULER.DROP_JOB (g_trim_errorlog_job_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      DBMS_SCHEDULER.CREATE_JOB (
         job_name          => g_trim_errorlog_job_name,
         job_type          => 'stored_procedure',
         job_action        => 'util.trim_errorlog',
         start_date        => NULL,
         repeat_interval   => 'freq=secondly; interval=300',
         job_class         => 'default_job_class',
         enabled           => TRUE,
         auto_drop         => FALSE,
         comments          => 'Trim Error Log Table');
   END START_TRIM_ERRORLOG_JOB;

   PROCEDURE STOP_TRIM_ERRORLOG_JOB
   IS
   BEGIN
      DBMS_SCHEDULER.drop_job (
         g_streams_user || '.' || g_trim_errorlog_job_name,
         TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('Error dropping trim errorlog job');
   END;

   PROCEDURE UPDATE_HEARTBEAT (p_source_db VARCHAR2)
   IS
   BEGIN
      UPDATE cwms_heartbeat
         SET source_db = p_source_db, alive = SYSTIMESTAMP
       WHERE SOURCE_DB = p_source_db;

      COMMIT;
   END UPDATE_HEARTBEAT;

   PROCEDURE TRIM_ERRORLOG
   IS
      l_count   NUMBER;
   BEGIN
      SELECT COUNT (*) INTO l_count FROM ERRORLOG;

      IF (l_count > 10000)
      THEN
         DELETE FROM ERRORLOG;
      END IF;

      COMMIT;
   END TRIM_ERRORLOG;


   PROCEDURE DELETE_ERROR_LOGS
   IS
      l_tables      DBMS_UTILITY.UNCL_ARRAY;
      l_tablename   VARCHAR2 (64);
   BEGIN
      l_tables := GET_COPY_TABLES;

      FOR idx IN 1 .. l_tables.COUNT
      LOOP
         l_tablename := l_tables (idx);

         BEGIN
            EXECUTE IMMEDIATE
                  'DELETE FROM '
               || g_streams_user
               || '.'
               || REPLACE (l_tablename, 'AT_', 'ER_');

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;
   END DELETE_ERROR_LOGS;

   PROCEDURE DROP_ERROR_LOGS
   IS
      l_tables      DBMS_UTILITY.UNCL_ARRAY;
      l_tablename   VARCHAR2 (64);
   BEGIN
      l_tables := GET_COPY_TABLES;

      FOR idx IN 1 .. l_tables.COUNT
      LOOP
         l_tablename := l_tables (idx);

         BEGIN
            EXECUTE IMMEDIATE
                  'DROP TABLE '
               || g_streams_user
               || '.'
               || REPLACE (l_tablename, 'AT_', 'ER_');
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;
   END DROP_ERROR_LOGS;

   PROCEDURE CREATE_ERROR_LOGS
   IS
      l_tables      DBMS_UTILITY.UNCL_ARRAY;
      l_createcmd   VARCHAR2 (256);
      l_tablename   VARCHAR2 (64);
   BEGIN
      l_tables := GET_COPY_TABLES;

      FOR idx IN 1 .. l_tables.COUNT
      LOOP
         l_tablename := l_tables (idx);

         DBMS_ERRLOG.CREATE_ERROR_LOG (g_cwms_user || '.' || l_tablename,
                                       REPLACE (l_tablename, 'AT_', 'ER_'),
                                       g_streams_user,
                                       NULL,
                                       TRUE);
      END LOOP;

      COMMIT;
   END CREATE_ERROR_LOGS;

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
   END GET_COL_LIST;

   PROCEDURE COPY_TABLES (p_tables      DBMS_UTILITY.UNCL_ARRAY,
                          p_fromUser    VARCHAR2,
                          p_toUser      VARCHAR2,
                          p_fromLink    VARCHAR2)
   IS
      l_insert_col   VARCHAR2 (2048);
      l_copycmd      VARCHAR2 (4096);
      l_tablename    VARCHAR (64);
   BEGIN
      DELETE_ERROR_LOGS;
      STOP_ALL_APPLY;
      --CREATE_ERROR_LOGS;

      TOGGLE_FK_CONSTRAINTS (GET_STREAMING_TABLES, 'ENABLED', 'DISABLE');
      TOGGLE_TRIGGERS (GET_STREAMING_TABLES, 'ENABLED', 'DISABLE');

      FOR idx IN 1 .. p_tables.COUNT
      LOOP
         l_tablename := p_tables (idx);

         l_insert_col := GET_COL_LIST (l_tablename, p_fromUser);
         l_copycmd :=
               'INSERT INTO '
            || p_toUser
            || '.'
            || l_tablename
            || ' ( '
            || l_insert_col
            || ' ) (SELECT '
            || l_insert_col
            || ' FROM '
            || p_fromUser
            || '.'
            || l_tablename
            || '@'
            || p_fromLink
            || ')'
            || ' LOG ERRORS INTO '
            || g_streams_user
            || '.'
            || REPLACE (l_tablename, 'AT_', 'ER_')
            || ' REJECT LIMIT UNLIMITED';

         DBMS_OUTPUT.PUT_LINE (l_copycmd);

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
               DBMS_OUTPUT.put_line (
                  'Error inserting into ' || l_tablename || ' ' || l_copycmd);
               DBMS_OUTPUT.put_line (SQLERRM);
               DBMS_OUTPUT.put_line (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         END;
      END LOOP;

      TOGGLE_FK_CONSTRAINTS (p_tables, 'DISABLED', 'ENABLE');
      TOGGLE_TRIGGERS (p_tables, 'DISABLED', 'ENABLE');

      COMMIT;
   END COPY_TABLES;

   PROCEDURE COPY_AT_TABLES (p_fromLink VARCHAR2)
   IS
   BEGIN
      COPY_TABLES (GET_COPY_TABLES,
                   g_cwms_user,
                   g_cwms_user,
                   p_fromLink);
   END COPY_AT_TABLES;

   PROCEDURE COPY_EDS_TABLES (p_fromLink VARCHAR2)
   IS
   BEGIN
      COPY_TABLES (GET_EDS_TABLES,
                   g_cwms_user,
                   g_cwms_user,
                   p_fromLink);
   END COPY_EDS_TABLES;

   PROCEDURE TOGGLE_FK_CONSTRAINTS (p_tables   IN DBMS_UTILITY.UNCL_ARRAY,
                                    p_flag1    IN VARCHAR2,
                                    p_flag2    IN VARCHAR2)
   IS
      l_table_name   VARCHAR2 (64);
   BEGIN
      FOR idx IN 1 .. p_tables.COUNT
      LOOP
         l_table_name :=
            SUBSTR (p_tables (idx), INSTR (p_tables (idx), '.') + 1);

         FOR C
            IN (SELECT c.owner, c.table_name, c.constraint_name
                  FROM all_constraints c, all_tables t
                 WHERE     c.table_name = t.table_name
                       AND c.status = p_flag1
                       AND c.owner = g_cwms_user
                       AND c.constraint_type = 'R'
                       AND c.table_name = l_table_name)
         LOOP
            DBMS_UTILITY.exec_ddl_statement (
                  'alter table '
               || c.owner
               || '.'
               || l_table_name
               || ' '
               || p_flag2
               || ' constraint '
               || c.constraint_name);
         END LOOP;
      END LOOP;
   END TOGGLE_FK_CONSTRAINTS;

   PROCEDURE TOGGLE_TRIGGERS (p_tables   IN DBMS_UTILITY.UNCL_ARRAY,
                              p_flag1       VARCHAR2,
                              p_flag2       VARCHAR2)
   IS
      l_table_name   VARCHAR2 (64);
   BEGIN
      FOR idx IN 1 .. p_tables.COUNT
      LOOP
         l_table_name :=
            SUBSTR (p_tables (idx), INSTR (p_tables (idx), '.') + 1);

         FOR c
            IN (SELECT d.table_owner, d.table_name, d.trigger_name
                  FROM all_triggers d
                 WHERE     d.status = p_flag1
                       AND d.table_owner = g_cwms_user
                       AND d.table_name = l_table_name)
         LOOP
            DBMS_UTILITY.exec_ddl_statement (
                  'alter trigger '
               || c.table_owner
               || '.'
               || c.trigger_name
               || ' '
               || p_flag2);
         END LOOP;
      END LOOP;
   END TOGGLE_TRIGGERS;

   PROCEDURE MERGE_TSV_TABLES (p_numberOfDays NUMBER, p_fromLink VARCHAR2)
   IS
      l_tables      DBMS_UTILITY.UNCL_ARRAY;
      l_merge_cmd   VARCHAR2 (2048);
   BEGIN
      l_tables := GET_MERGE_TSV_TABLES;

      FOR idx IN 1 .. l_tables.COUNT
      LOOP
         l_merge_cmd :=
               'MERGE INTO '
            || l_tables (idx)
            || ' d
        	       USING (SELECT *
              	       	     FROM '
            || l_tables (idx)
            || '@'
            || p_fromLink
            || ' WHERE data_entry_date > SYSDATE - '
            || p_numberOfDays
            || ') s
        		     ON (    s.ts_code = d.ts_code
            		     AND s.version_date = d.version_date
            		     AND s.date_time = d.date_time)
            		     WHEN MATCHED
            		     THEN
            		     UPDATE SET
                	     d.data_entry_date = s.data_entry_date,
                	     d.VALUE = s.VALUE,
                	     d.quality_code = s.quality_code
            		     WHEN NOT MATCHED
            		     THEN
            		     INSERT     (d.ts_code,
               		     d.date_time,
               		     d.version_date,
               		     d.data_entry_date,
               		     d.VALUE,
               		     d.quality_code)
            		     VALUES (s.ts_code,
               		     s.date_time,
               		     s.version_date,
               		     s.data_entry_date,
               		     s.VALUE,
               		     s.quality_code)';
         DBMS_OUTPUT.PUT_LINE (l_merge_cmd);

         EXECUTE IMMEDIATE l_merge_cmd;

         COMMIT;
      END LOOP;
   END MERGE_TSV_TABLES;

   PROCEDURE CREATE_CAPTURE_RULESET
   IS
   BEGIN
      DBMS_RULE_ADM.create_rule_set (
         rule_set_name        => g_cwms_ruleset_name,
         evaluation_context   => 'SYS.STREAMS$_EVALUATION_CONTEXT',
         rule_set_comment     => 'Rule set to capture/propagate/apply CWMS AT tables');
   END CREATE_CAPTURE_RULESET;

   PROCEDURE CREATE_CAPTURE_RULES (p_tables         DBMS_UTILITY.UNCL_ARRAY,
                                   p_rule_prefix    VARCHAR2)
   IS
      l_owner        VARCHAR2 (64);
      l_table_name   VARCHAR2 (64);
      l_rule_name    VARCHAR2 (70);
   BEGIN
      FOR IDX IN 1 .. p_tables.COUNT
      LOOP
         l_owner :=
            SUBSTR (p_tables (idx), 1, INSTR (p_tables (idx), '.') - 1);
         l_table_name :=
            SUBSTR (p_tables (idx), INSTR (p_tables (idx), '.') + 1);
         l_rule_name := p_rule_prefix || '_' || idx;
         DBMS_RULE_ADM.create_rule (
            rule_name      => l_rule_name,
            condition      => '
                        (:dml.get_object_owner() ='''
                             || l_owner
                             || ''' AND :dml.get_object_name() ='''
                             || l_table_name
                             || ''')',
            rule_comment   =>   'Rule set to capture/propagate/apply '
                             || p_tables (idx)
                             || ' table');

         DBMS_RULE_ADM.ADD_RULE (l_rule_name, g_cwms_ruleset_name);
      END LOOP;
   END CREATE_CAPTURE_RULES;

   PROCEDURE DROP_CAPTURE_RULES
   IS
   BEGIN
      BEGIN
         DBMS_RULE_ADM.DROP_RULE_SET (g_cwms_ruleset_name, TRUE);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE ('Error dropping rule set: ' || SQLERRM);
      END;
   END DROP_CAPTURE_RULES;

   PROCEDURE CREATE_PROPAGATION (p_source_db VARCHAR2, p_dest_db VARCHAR2)
   IS
   BEGIN
      DBMS_PROPAGATION_ADM.CREATE_PROPAGATION (
         PROPAGATION_NAME     => GET_PROPAGATION_NAME (p_source_db),
         source_queue         => GET_CAPTURE_QUEUE_NAME (p_source_db),
         destination_queue    => GET_APPLY_QUEUE_NAME (p_source_db),
         destination_dblink   => p_dest_db);
   END CREATE_PROPAGATION;

   PROCEDURE DROP_PROPAGATION (p_source_db VARCHAR2)
   IS
   BEGIN
      BEGIN
         DBMS_PROPAGATION_ADM.STOP_PROPAGATION (
            GET_PROPAGATION_NAME (p_source_db));
         DBMS_PROPAGATION_ADM.DROP_PROPAGATION (
            GET_PROPAGATION_NAME (p_source_db),
            TRUE);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (
               'Error while stopping/dropping propagation: ' || SQLERRM);
      END;
   END DROP_PROPAGATION;

   PROCEDURE INSTANTIATE_CAPTURE
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
      l_tables := util.get_streaming_tables;

      FOR IDX IN 1 .. l_tables.COUNT
      LOOP
         DBMS_CAPTURE_ADM.PREPARE_TABLE_INSTANTIATION (l_tables (idx));
      END LOOP;
   END;

   PROCEDURE CREATE_CAPTURE (p_source_db VARCHAR2)
   IS
      l_scn   NUMBER;
   BEGIN
      DBMS_CAPTURE_ADM.BUILD (l_scn);
      DBMS_CAPTURE_ADM.CREATE_CAPTURE (
         queue_name                  => GET_CAPTURE_QUEUE_NAME (p_source_db),
         capture_name                => GET_CAPTURE_NAME (p_source_db),
         rule_set_name               => g_cwms_ruleset_name,
         first_scn                   => l_scn,
         checkpoint_retention_time   => 0.2);
      INSTANTIATE_CAPTURE;
   END CREATE_CAPTURE;

   PROCEDURE DROP_CAPTURE (p_source_db VARCHAR2)
   IS
   BEGIN
      BEGIN
         DBMS_CAPTURE_ADM.STOP_CAPTURE (GET_CAPTURE_NAME (p_source_db));
         DBMS_CAPTURE_ADM.DROP_CAPTURE (GET_CAPTURE_NAME (p_source_db));
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (
               'Error stopping dropping capture: ' || SQLERRM);
      END;
   END DROP_CAPTURE;

   FUNCTION PREPARE_SOURCE_DB (p_source_db VARCHAR2, p_dest_db VARCHAR2)
      RETURN NUMBER
   IS
      l_scn   NUMBER;
   BEGIN
      CREATE_QUEUE (p_source_db, 'CAPTURE');
      CREATE_CAPTURE_RULESET;
      CREATE_CAPTURE_RULES (GET_STREAMING_TABLES, g_cwms_rule_name);
      CREATE_PROPAGATION (p_source_db, p_dest_db);

      CREATE_CAPTURE (p_source_db);

      SELECT DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER INTO l_scn FROM DUAL;

      INSERT INTO cwms_heartbeat
           VALUES (p_source_db, NULL);

      EXECUTE IMMEDIATE
            'BEGIN UTIL.COPY_AT_TABLES@'
         || p_dest_db
         || '( '''
         || p_source_db
         || '''); END;';


      --CREATE_CAPTURE (p_source_db);
      COMMIT;
      RETURN l_scn;
   END PREPARE_SOURCE_DB;

   FUNCTION PREPARE_SOURCE_DB_EDS (p_source_db VARCHAR2, p_dest_db VARCHAR2)
      RETURN NUMBER
   IS
      l_scn   NUMBER;
   BEGIN
      SELECT DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER INTO l_scn FROM DUAL;

      EXECUTE IMMEDIATE
            'BEGIN UTIL.COPY_EDS_TABLES@'
         || p_dest_db
         || '( '''
         || p_source_db
         || '''); END;';

      EXECUTE IMMEDIATE
         'CREATE OR REPLACE DIRECTORY CWMS_STR_TMP AS ''/tmp''';

      DBMS_OUTPUT.PUT_LINE (
         GET_APPLY_QUEUE_NAME (p_source_db) || '@' || p_source_db);
      extended_datatype_support.set_up_source_tables (
         table_names               => GET_EDS_TABLES,
         capture_name              => GET_CAPTURE_NAME (p_source_db),
         source_database           => p_source_db,
         source_queue_name         => GET_CAPTURE_QUEUE_NAME (p_source_db),
         propagation_name          => GET_PROPAGATION_NAME (p_source_db),
         destination_queue_name    =>   GET_APPLY_QUEUE_NAME (p_source_db)
                                     || '@'
                                     || p_dest_db,
         script_directory_object   => 'CWMS_STR_TMP',
         script_name_prefix        => 'CWMS_STR',
         add_capture_rules         => FALSE,
         add_propagation_rules     => FALSE);

      EXECUTE IMMEDIATE 'DROP DIRECTORY CWMS_STR_TMP';

      CREATE_CAPTURE_RULES (GET_STREAMING_EDS_TABLES, g_cwms_eds_rule_name);
      COMMIT;
      RETURN l_scn;
   END PREPARE_SOURCE_DB_EDS;

   PROCEDURE RESET_SCN
   IS
      l_required_scn   NUMBER;

      l_first_scn      NUMBER;
      l_applied_scn    NUMBER;
      l_capture_name   VARCHAR2 (64);
   BEGIN
      SELECT CAPTURE_NAME, APPLIED_SCN, REQUIRED_CHECKPOINT_SCN
        INTO l_capture_name, l_applied_scn, l_required_scn
        FROM DBA_CAPTURE;

      IF ( (l_required_scn > l_applied_scn) AND (l_applied_scn > 0))
      THEN
         l_first_scn := l_applied_scn;
      ELSIF (l_required_scn > 0)
      THEN
         l_first_scn := l_required_scn;
      ELSE
         RETURN;
      END IF;

      DBMS_OUTPUT.PUT_LINE (
            'Capture Process '
         || l_capture_name
         || ' APPLIED_SCN '
         || l_applied_scn
         || ' REQUIRED_SCN '
         || l_required_scn
         || ' FIRST SCN '
         || l_first_scn);
      DBMS_CAPTURE_ADM.stop_capture (l_capture_name);
      DBMS_CAPTURE_ADM.ALTER_CAPTURE (capture_name   => l_capture_name,
                                      start_scn      => l_required_scn,
                                      first_scn      => l_required_scn);
      DBMS_CAPTURE_ADM.start_capture (l_capture_name);
   END;

   PROCEDURE RESTART_ALL_CAPTURE
   IS
   BEGIN
      FOR C IN (SELECT CAPTURE_NAME
                  FROM DBA_CAPTURE
                 WHERE CAPTURE_USER = g_streams_user)
      LOOP
         DBMS_CAPTURE_ADM.STOP_CAPTURE (c.capture_name);
         DBMS_CAPTURE_ADM.START_CAPTURE (c.capture_name);
      END LOOP;
   END RESTART_ALL_CAPTURE;

   PROCEDURE START_ALL_CAPTURE
   IS
   BEGIN
      FOR C IN (SELECT CAPTURE_NAME
                  FROM DBA_CAPTURE
                 WHERE CAPTURE_USER = g_streams_user)
      LOOP
         DBMS_CAPTURE_ADM.STOP_CAPTURE (c.capture_name);
         DBMS_CAPTURE_ADM.START_CAPTURE (c.capture_name);
      END LOOP;
   END START_ALL_CAPTURE;

   PROCEDURE STOP_ALL_CAPTURE
   IS
   BEGIN
      FOR C IN (SELECT CAPTURE_NAME
                  FROM DBA_CAPTURE
                 WHERE CAPTURE_USER = g_streams_user)
      LOOP
         DBMS_CAPTURE_ADM.STOP_CAPTURE (c.capture_name);
      END LOOP;
   END STOP_ALL_CAPTURE;



   PROCEDURE RECREATE_CAPTURE (p_source_db         VARCHAR2,
                               p_dest_db           VARCHAR2,
                               p_number_of_days    NUMBER)
   IS
      l_scn   NUMBER;
   BEGIN
      DROP_CAPTURE (p_source_db);
      STOP_HEARTBEAT_JOB;

      UPDATE CWMS_HEARTBEAT
         SET alive = NULL
       WHERE source_db = p_source_db;

      EXECUTE IMMEDIATE
            'UPDATE CWMS_HEARTBEAT@'
         || p_dest_db
         || ' SET alive=NULL WHERE source_db='''
         || p_source_db
         || '''';

      CREATE_CAPTURE (p_source_db);

      EXECUTE IMMEDIATE
            'BEGIN UTIL.COPY_AT_TABLES@'
         || p_dest_db
         || '( '''
         || g_cwms_user
         || ''','''
         || g_cwms_user
         || ''','''
         || p_source_db
         || '''); END;';

      EXECUTE IMMEDIATE
            'BEGIN UTIL.MERGE_TSV_TABLES@'
         || p_dest_db
         || ' ('
         || p_number_of_days
         || ','''
         || p_source_db
         || '''); END;';


      DBMS_CAPTURE_ADM.start_capture (
         capture_name => GET_CAPTURE_NAME (p_source_db));
      START_HEARTBEAT_JOB (p_source_db);
      COMMIT;
   END;


   PROCEDURE CLEAN_SOURCE_DB (p_source_db VARCHAR2)
   IS
   BEGIN
      DROP_PROPAGATION (p_source_db);
      DROP_CAPTURE_RULES;
      DROP_CAPTURE (p_source_db);
      STOP_HEARTBEAT_JOB;

      DELETE FROM CWMS_HEARTBEAT
            WHERE SOURCE_DB = p_source_db;

      COMMIT;
   END;

   PROCEDURE CREATE_APPLY (p_source_db VARCHAR2)
   IS
   BEGIN
      DBMS_APPLY_ADM.CREATE_APPLY (
         queue_name        => GET_APPLY_QUEUE_NAME (p_source_db),
         apply_name        => GET_APPLY_NAME (p_source_db),
         apply_captured    => TRUE,
         source_database   => p_source_db);
   END CREATE_APPLY;

   PROCEDURE INSTANTIATE_APPLY (p_tables       DBMS_UTILITY.UNCL_ARRAY,
                                p_source_db    VARCHAR2,
                                p_scn          NUMBER)
   IS
   BEGIN
      FOR IDX IN 1 .. p_tables.COUNT
      LOOP
         DBMS_APPLY_ADM.SET_TABLE_INSTANTIATION_SCN (
            source_object_name     => p_tables (idx),
            source_database_name   => p_source_db,
            instantiation_scn      => p_scn);
      END LOOP;
   END INSTANTIATE_APPLY;

   PROCEDURE DROP_APPLY (p_source_db VARCHAR2)
   IS
   BEGIN
      BEGIN
         DBMS_APPLY_ADM.STOP_APPLY (GET_APPLY_NAME (p_source_db));
         DBMS_APPLY_ADM.DELETE_ALL_ERRORS (GET_APPLY_NAME (p_source_db));
         DBMS_APPLY_ADM.DROP_APPLY (GET_APPLY_NAME (p_source_db));
         INSTANTIATE_APPLY (GET_STREAMING_TABLES, p_source_db, NULL);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (
               'Error in dropping/stopping apply: ' || SQLERRM);
      END;
   END DROP_APPLY;



   PROCEDURE SETUP_APPLY (p_source_db VARCHAR2)
   IS
      l_tables   DBMS_UTILITY.UNCL_ARRAY;
   BEGIN
      DBMS_APPLY_ADM.SET_PARAMETER (GET_APPLY_NAME (p_source_db),
                                    'disable_on_error',
                                    'N');
      l_tables := UTIL.GET_APPLY_HANDLER_TABLES;

      FOR idx IN 1 .. l_tables.COUNT
      LOOP
         DBMS_APPLY_ADM.set_dml_handler (
            object_name      => l_tables (idx),
            object_type      => 'TABLE',
            operation_name   => 'INSERT',
            error_handler    => TRUE,
            user_procedure   => g_streams_user
                               || '.CONFLICT_HANDLERS.RESOLVE_CONFLICTS');
         DBMS_APPLY_ADM.set_dml_handler (
            object_name      => l_tables (idx),
            object_type      => 'TABLE',
            operation_name   => 'UPDATE',
            error_handler    => TRUE,
            user_procedure   => g_streams_user
                               || '.CONFLICT_HANDLERS.RESOLVE_CONFLICTS');
         DBMS_APPLY_ADM.set_dml_handler (
            object_name      => l_tables (idx),
            object_type      => 'TABLE',
            operation_name   => 'DELETE',
            error_handler    => TRUE,
            user_procedure   => g_streams_user
                               || '.CONFLICT_HANDLERS.RESOLVE_CONFLICTS');
         DBMS_APPLY_ADM.COMPARE_OLD_VALUES (object_name   => l_tables (idx),
                                            column_list   => '*',
                                            operation     => 'DELETE',
                                            compare       => FALSE);
         DBMS_APPLY_ADM.COMPARE_OLD_VALUES (object_name   => l_tables (idx),
                                            column_list   => '*',
                                            operation     => 'UPDATE',
                                            compare       => FALSE);
      END LOOP;
   END SETUP_APPLY;

   PROCEDURE PREPARE_DEST_DB (p_source_db VARCHAR2, p_scn NUMBER)
   IS
   BEGIN
      CREATE_QUEUE (p_source_db, 'APPLY');
      CREATE_APPLY (p_source_db);
      SETUP_APPLY (p_source_db);
      INSTANTIATE_APPLY (GET_STREAMING_TABLES, p_source_db, p_scn);
      START_TRIM_ERRORLOG_JOB;

      --INSERT INTO cwms_heartbeat
      --VALUES (p_source_db, NULL);

      START_ALL_APPLY;
      COMMIT;
   END;

   PROCEDURE PREPARE_DEST_DB_EDS (p_source_db VARCHAR2, p_scn NUMBER)
   IS
   BEGIN
      EXECUTE IMMEDIATE
         'CREATE OR REPLACE DIRECTORY CWMS_STR_TMP AS ''/tmp''';

      extended_datatype_support.set_up_destination_tables (
         table_names               => GET_EDS_TABLES,
         apply_name                => GET_APPLY_NAME (p_source_db),
         source_database           => p_source_db,
         destination_queue_name    => GET_APPLY_QUEUE_NAME (p_source_db),
         script_directory_object   => 'CWMS_STR_TMP',
         script_name_prefix        => 'CWMS_STR',
         add_apply_rules           => FALSE);
      INSTANTIATE_APPLY (GET_STREAMING_EDS_TABLES, p_source_db, p_scn);

      EXECUTE IMMEDIATE 'DROP DIRECTORY CWMS_STR_TMP';

      COMMIT;
   END PREPARE_DEST_DB_EDS;

   PROCEDURE CLEAN_DEST_DB (p_source_db VARCHAR2)
   IS
   BEGIN
      DROP_APPLY (p_source_db);

      DELETE FROM CWMS_HEARTBEAT
            WHERE SOURCE_DB = p_source_db;

      DELETE FROM ERRORLOG;

      STOP_TRIM_ERRORLOG_JOB;
      COMMIT;
   END CLEAN_DEST_DB;

   PROCEDURE START_STREAMS (p_source_db VARCHAR2, p_dest_db VARCHAR2)
   IS
      l_scn   NUMBER;
      l_cmd   VARCHAR2 (128);
   BEGIN
      l_scn := PREPARE_SOURCE_DB (p_source_db, p_dest_db);

      l_cmd :=
            'BEGIN UTIL.PREPARE_DEST_DB@'
         || P_DEST_DB
         || '('''
         || p_source_db
         || ''','
         || l_scn
         || '); END;';

      DBMS_OUTPUT.PUT_LINE ('Preparing destination: ' || l_cmd);

      EXECUTE IMMEDIATE l_cmd;



      BEGIN
         DBMS_AQADM.enable_propagation_schedule (
            queue_name          => GET_CAPTURE_QUEUE_NAME (p_source_db),
            destination         => p_dest_db,
            destination_queue   => GET_APPLY_QUEUE_NAME (p_source_db));
      EXCEPTION
         WHEN OTHERS
         THEN
            IF SQLCODE = -24064
            THEN
               NULL;
            ELSE
               RAISE;
            END IF;
      END;

      DBMS_OUTPUT.PUT_LINE ('Starting Capture');
      START_ALL_CAPTURE;
      START_HEARTBEAT_JOB (p_source_db);
      START_RESET_SCN_JOB;
      COMMIT;
   END START_STREAMS;

   PROCEDURE START_STREAMS_EDS (p_source_db VARCHAR2, p_dest_db VARCHAR2)
   IS
      l_scn   NUMBER;
      l_cmd   VARCHAR2 (128);
   BEGIN
      STOP_ALL_CAPTURE;

      EXECUTE IMMEDIATE 'BEGIN UTIL.STOP_ALL_APPLY@' || p_dest_db || ';END;';

      l_scn := PREPARE_SOURCE_DB_EDS (p_source_db, p_dest_db);

      l_cmd :=
            'BEGIN UTIL.PREPARE_DEST_DB_EDS@'
         || P_DEST_DB
         || '('''
         || p_source_db
         || ''','
         || l_scn
         || '); END;';

      DBMS_OUTPUT.PUT_LINE ('Preparing destination: ' || l_cmd);

      EXECUTE IMMEDIATE l_cmd;


      EXECUTE IMMEDIATE 'BEGIN UTIL.START_ALL_APPLY@' || p_dest_db || ';END;';

      START_ALL_CAPTURE;
      COMMIT;
   END START_STREAMS_EDS;
END Util;
/

SHOW ERRORS;

COMMIT;


@../defines
set serveroutput on

whenever sqlerror exit;

spool install_streams.log

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&source_db_streams_password@&source_db_url

whenever sqlerror continue;

drop database link &dest_db_name;

whenever sqlerror exit;

CREATE DATABASE LINK &dest_db_name CONNECT TO &streams_user IDENTIFIED BY &dest_db_streams_password USING '&dest_db_url';

DECLARE
   l_tables   DBMS_UTILITY.UNCL_ARRAY;
   l_scn      NUMBER;
BEGIN
   DBMS_OUTPUT.PUT_LINE ('Creating destination database link');

   INSERT INTO cwms_heartbeat
        VALUES ('&SOURCE_DB_NAME', NULL);

   INSERT INTO cwms_heartbeat@&DEST_DB_NAME
        VALUES ('&SOURCE_DB_NAME', NULL);

   COMMIT;


   DBMS_OUTPUT.PUT_LINE ('Creating capture  queue');

   DBMS_STREAMS_ADM.set_up_queue (
      queue_table      => '"&STREAMS_USER"."CAPQT64_&SOURCE_DB_NAME"',
      storage_clause   => NULL,
      queue_name       => '"&STREAMS_USER"."CAPQ64_&SOURCE_DB_NAME"');

   DBMS_OUTPUT.PUT_LINE ('Creating apply  queue');

   DBMS_STREAMS_ADM.set_up_queue@&dest_db_name (
      queue_table      => '"&STREAMS_USER"."APPQT64_&SOURCE_DB_NAME"',
      storage_clause   => NULL,
      queue_name       => '"&STREAMS_USER"."APPQ64_&SOURCE_DB_NAME"');

   DBMS_OUTPUT.PUT_LINE ('Creating   rule set');
   DBMS_RULE_ADM.create_rule_set (
      rule_set_name        => 'CWMS_AT_RULESET',
      evaluation_context   => 'SYS.STREAMS$_EVALUATION_CONTEXT',
      rule_set_comment     => 'Rule set to capture/propagate/apply CWMS AT tables');

   DBMS_OUTPUT.PUT_LINE ('Creating rule');
   DBMS_RULE_ADM.create_rule (
      rule_name      => 'CWMS_AT_RULE',
      condition      => '(((:dml.get_object_name()  LIKE ''AT_%'' or :dml.get_object_name() = ''CWMS_HEARTBEAT'')
                AND :dml.get_object_name()  NOT IN
                       (''AT_LOG_MESSAGE'',
                        ''AT_LOG_MESSAGE_PROPERTIES'',
                        ''AT_TS_MSG_ARCHIVE_1'',
                        ''AT_TS_MSG_ARCHIVE_2'',
                        ''AT_TS_DELETED_TIMES'')
                AND :dml.get_object_name()  <> ''AT_GEOGRAPHIC_LOCATION''
                AND :dml.get_object_name()  NOT IN
                       (''AT_TSV'',
                        ''AT_TSV_ARCHIVAL'',
                        ''AT_TSV_2002'',
                        ''AT_TSV_2003'',
                        ''AT_TSV_2004'',
                        ''AT_TSV_2005'',
                        ''AT_TSV_2006'',
                        ''AT_TSV_2007'',
                        ''AT_TSV_2008'',
                        ''AT_TSV_2009'',
                        ''AT_TSV_2010'',
                        ''AT_TSV_2011'',
                        ''AT_TSV_2012'',
                        ''AT_TSV_2015'',
                        ''AT_TSV_2016'',
                        ''AT_TSV_2017'',
                        ''AT_TSV_2018'',
                        ''AT_TSV_2019'',
                        ''AT_TSV_2020'',
                        ''AT_TSV_INF_AND_BEYOND'')) and
                        (:dml.get_object_owner() = ''&CWMS_SCHEMA'' or :dml.get_object_owner() = ''&STREAMS_USER''))',
      rule_comment   => 'Rule set to capture/propagate/apply CWMS AT tables');

   DBMS_OUTPUT.PUT_LINE ('Adding rule');

   DBMS_RULE_ADM.ADD_RULE ('CWMS_AT_RULE', 'CWMS_AT_RULESET');

   DBMS_OUTPUT.PUT_LINE ('Creating propagation');
   DBMS_PROPAGATION_ADM.CREATE_PROPAGATION (
      propagation_name     => 'PROP64_&SOURCE_DB_NAME',
      source_queue         => '"CWMS_STR_ADM"."CAPQ64_&SOURCE_DB_NAME"',
      destination_queue    => '"CWMS_STR_ADM"."APPQ64_&SOURCE_DB_NAME"',
      destination_dblink   => '&DEST_DB_NAME');

   DBMS_OUTPUT.PUT_LINE ('Creating capture');
   DBMS_CAPTURE_ADM.CREATE_CAPTURE (
      queue_name      => '"CWMS_STR_ADM"."CAPQ64_&SOURCE_DB_NAME"',
      capture_name    => 'CAP64_&SOURCE_DB_NAME',
      rule_set_name   => 'CWMS_AT_RULESET');

   l_tables := util.get_streaming_tables;

   DBMS_OUTPUT.PUT_LINE ('Creating Supplemental logs');

   FOR IDX IN 1 .. l_tables.COUNT
   LOOP
      DBMS_CAPTURE_ADM.PREPARE_TABLE_INSTANTIATION (l_tables (idx));
   END LOOP;

   DBMS_OUTPUT.PUT_LINE ('Creating apply  ');

   DBMS_APPLY_ADM.CREATE_APPLY@&DEST_DB_NAME (
      queue_name        => '"CWMS_STR_ADM"."APPQ64_&SOURCE_DB_NAME"',
      apply_name        => 'APP64_&SOURCE_DB_NAME',
      apply_captured    => TRUE,
      source_database   => '&SOURCE_DB_NAME');

   DBMS_OUTPUT.PUT_LINE ('Instantiate destination tables');

   SELECT DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER@&SOURCE_DB_NAME
     INTO l_scn
     FROM DUAL;

   FOR idx IN 1 .. l_tables.COUNT
   LOOP
      DBMS_APPLY_ADM.SET_TABLE_INSTANTIATION_SCN@&DEST_DB_NAME (
         source_object_name     => l_tables (idx),
         source_database_name   => '&source_db_name',
         instantiation_scn      => l_scn);
   END LOOP;

   DBMS_APPLY_ADM.SET_PARAMETER@&dest_db_name ('APP64_&SOURCE_DB_NAME',
                                               'disable_on_error',
                                               'N');

   DBMS_OUTPUT.PUT_LINE ('Set Apply handlers');

   l_tables := UTIL.GET_APPLY_HANDLER_TABLES;

   FOR idx IN 1 .. l_tables.COUNT
   LOOP
      DBMS_APPLY_ADM.set_dml_handler@&dest_db_name (
         object_name      => '&CWMS_SCHEMA..' || l_tables (idx),
         object_type      => 'TABLE',
         operation_name   => 'INSERT',
         error_handler    => TRUE,
         user_procedure   => '&STREAMS_USER..CONFLICT_HANDLERS.RESOLVE_CONFLICTS');
      DBMS_APPLY_ADM.set_dml_handler@&dest_db_name (
         object_name      => '&CWMS_SCHEMA..' || l_tables (idx),
         object_type      => 'TABLE',
         operation_name   => 'UPDATE',
         error_handler    => TRUE,
         user_procedure   => '&STREAMS_USER..CONFLICT_HANDLERS.RESOLVE_CONFLICTS');
      DBMS_APPLY_ADM.set_dml_handler@&dest_db_name (
         object_name      => '&CWMS_SCHEMA..' || l_tables (idx),
         object_type      => 'TABLE',
         operation_name   => 'DELETE',
         error_handler    => TRUE,
         user_procedure   => '&STREAMS_USER..CONFLICT_HANDLERS.REOLVE_CONFLICTS');
      DBMS_APPLY_ADM.COMPARE_OLD_VALUES(
	object_name        =>'&CWMS_SCHEMA..' || l_tables (idx),
   	column_list         => '*',
   	operation          => 'DELETE',
   	compare             => FALSE);
      DBMS_APPLY_ADM.COMPARE_OLD_VALUES(
	object_name        =>'&CWMS_SCHEMA..' || l_tables (idx),
   	column_list         => '*',
   	operation          => 'UPDATE',
   	compare             => FALSE);
   	 
   END LOOP;


   UTIL.COPY_AT_TABLES@&DEST_DB_NAME ( '&CWMS_SCHEMA',
                                      '&CWMS_SCHEMA',
                                      '&SOURCE_DB_NAME');

   DBMS_OUTPUT.PUT_LINE ('Starting Apply');
   DBMS_APPLY_ADM.START_APPLY@&DEST_DB_NAME ('APP64_&SOURCE_DB_NAME');



   DBMS_OUTPUT.PUT_LINE ('Starting Propagation');

   BEGIN
      DBMS_AQADM.enable_propagation_schedule (
         queue_name          => '"&STREAMS_USER"."CAPQ64_&SOURCE_DB_NAME"',
         destination         => '&DEST_DB_NAME',
         destination_queue   => '"&STREAMS_USER"."APPQ64_&SOURCE_DB_NAME"');
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
   DBMS_CAPTURE_ADM.start_capture (capture_name => 'CAP64_&SOURCE_DB_NAME');

   DBMS_OUTPUT.PUT_LINE ('Starting heartbeat');
   UTIL.START_HEARTBEAT_JOB;

   DBMS_OUTPUT.PUT_LINE ('Starting trim errorlog');
   UTIL.START_TRIM_ERRORLOG_JOB@&DEST_DB_NAME;
END;

/

exit;

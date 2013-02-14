/* Formatted on 1/18/2013 11:16:15 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE CWMS_STR_ADM.UTIL
   AUTHID CURRENT_USER
AS
   g_cwms_user                  CONSTANT VARCHAR2 (64) := '&cwms_schema';
   g_streams_user               CONSTANT VARCHAR2 (64) := '&streams_user';
   g_cwms_rule_name             CONSTANT VARCHAR2 (24) := 'CWMS_AT_RULE';
   g_cwms_eds_rule_name             CONSTANT VARCHAR2 (24) := 'CWMS_EDS_AT_RULE';
   g_cwms_ruleset_name          CONSTANT VARCHAR2 (24) := 'CWMS_AT_RULESET';
   g_heartbeat_job_name   VARCHAR2 (32) := 'STREAMS_HEARTBEAT_JOB';
   g_trim_errorlog_job_name   VARCHAR2 (32) := 'STREAMS_TRIM_ERRORLOG_JOB';
   g_reset_scn_job_name           VARCHAR2 (32) := 'STREAMS_RESET_SCN_JOB';

   PROCEDURE START_HEARTBEAT_JOB (p_source_db VARCHAR2);

   PROCEDURE STOP_HEARTBEAT_JOB;

   PROCEDURE START_TRIM_ERRORLOG_JOB;

   PROCEDURE STOP_TRIM_ERRORLOG_JOB;

   PROCEDURE START_RESET_SCN_JOB;

   PROCEDURE UPDATE_HEARTBEAT (p_source_db VARCHAR2);

   PROCEDURE TRIM_ERRORLOG;

   PROCEDURE COPY_AT_TABLES (p_fromLink VARCHAR2);
   PROCEDURE COPY_EDS_TABLES (p_fromLink VARCHAR2);

   PROCEDURE TOGGLE_FK_CONSTRAINTS (p_tables   IN DBMS_UTILITY.UNCL_ARRAY,
                                    p_flag1    IN VARCHAR2,
                                    p_flag2    IN VARCHAR2);


   PROCEDURE TOGGLE_TRIGGERS (p_tables   IN DBMS_UTILITY.UNCL_ARRAY,
                              p_flag1       VARCHAR2,
                              p_flag2       VARCHAR2);


   FUNCTION PREPARE_SOURCE_DB (p_source_db VARCHAR2, p_dest_db VARCHAR2)
      RETURN NUMBER;

   PROCEDURE PREPARE_DEST_DB (p_source_db VARCHAR2, p_scn NUMBER);
   PROCEDURE PREPARE_DEST_DB_EDS (p_source_db VARCHAR2, p_scn NUMBER);



   PROCEDURE CLEAN_SOURCE_DB (p_source_db VARCHAR2);

   PROCEDURE CLEAN_DEST_DB (p_source_db VARCHAR2);

   PROCEDURE START_STREAMS (p_source_db VARCHAR2, p_dest_db VARCHAR2);
   PROCEDURE START_STREAMS_EDS (p_source_db VARCHAR2, p_dest_db VARCHAR2);

   PROCEDURE RECREATE_CAPTURE (p_source_db         VARCHAR2,
                              p_dest_db           VARCHAR2,
                              p_number_of_days    NUMBER);

   PROCEDURE RESET_SCN;

   PROCEDURE MERGE_TSV_TABLES (p_numberOfDays NUMBER, p_fromLink VARCHAR2);

   FUNCTION GET_STREAMING_TABLES
      RETURN DBMS_UTILITY.UNCL_ARRAY;

   PROCEDURE CREATE_ERROR_LOGS;

   PROCEDURE DELETE_ERROR_LOGS;

   PROCEDURE DROP_ERROR_LOGS;

   PROCEDURE START_ALL_APPLY;

   PROCEDURE STOP_ALL_APPLY;
   PROCEDURE RESTART_ALL_CAPTURE;
   PROCEDURE STOP_ALL_CAPTURE;
END UTIL;
/

SHOW ERRORS;

COMMIT;


connect / as sysdba
define cwms_schema = CWMS_20
set define on
set verify off
alter session set current_schema=&cwms_schema;
alter system enable restricted session;
whenever sqlerror exit sql.sqlcode

spool updateCWMS21_DB.log
 
PROMPT Creating AT_SEC_CWMS_USERS and AT_SEC_CWMS_PERMISSIONS tables

INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20047, 'SESSION_OFFICE_ID_NOT_SET', 'Session office id is not set by the application');
@@../cwms/at_schema_sec_2

PROMPT Update packages/types/views
@@../cwms/updateCwmsSchema
@@../cwms/views/av_sec_users
CREATE PUBLIC SYNONYM CWMS_ALARM FOR CWMS_20.CWMS_ALARM;
GRANT EXECUTE ON &CWMS_SCHEMA..LOC_LVL_INDICATOR_COND_T TO CWMS_USER;
GRANT EXECUTE ON &CWMS_SCHEMA..RATING_T TO CWMS_USER;

-- Context needs to be created after the package is created
@@../cwms/at_schema_env

@@import_cwms_permissions

PROMPT Recreating at_sec_users_r02 constraint

alter table at_sec_users drop constraint at_sec_users_r02;

@@insert_new_groups

ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r02
 FOREIGN KEY (username)
 REFERENCES at_sec_cwms_users (userid))
/


PROMPT Dropping AT_SEC_USER_OFFICE table

drop table at_sec_user_office;


COMMIT;
alter system disable restricted session;
exit;

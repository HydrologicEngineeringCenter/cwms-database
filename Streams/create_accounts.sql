set serveroutput on

whenever sqlerror exit;


prompt This script will drop and create streams admin user 
prompt
prompt Enter SYS password:
define db_sys_password = &1
prompt Enter DB URL:
define db_url = &2
prompt



PROMPT Connecting to database 

connect sys/"&db_sys_password"@&db_url as sysdba

PROMPT Kill Streams Sessions
@@kill_streams_session

whenever sqlerror continue;

PROMPT dropping streams user

drop user &streams_user cascade;

whenever sqlerror exit;

PROMPT Create streams user
@@create_streams_user &streams_user &dest_db_streams_password
@@create_streams_tables


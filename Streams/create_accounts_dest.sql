@defines
set serveroutput on

spool create_accounts_dest.log


@Streams/create_accounts &dest_db_sys_password &dest_db_url

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&dest_db_streams_password@&dest_db_url

whenever sqlerror continue;

DROP DATABASE LINK &source_db_name;

Whenever sqlerror exit;

CREATE DATABASE LINK &source_db_name CONNECT TO &streams_user IDENTIFIED BY &source_db_streams_password USING '&source_db_url';

@@InstallPackages

exec util.CREATE_ERROR_LOGS
exit


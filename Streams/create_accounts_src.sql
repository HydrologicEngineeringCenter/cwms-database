@defines
set serveroutput on

spool create_accounts_src.log


@Streams/create_accounts &source_db_sys_password &source_db_url

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&source_db_streams_password@&source_db_url

whenever sqlerror continue;

DROP DATABASE LINK &dest_db_name;

Whenever sqlerror exit;

CREATE DATABASE LINK &dest_db_name CONNECT TO &streams_user IDENTIFIED BY &dest_db_streams_password USING '&dest_db_url';

@@InstallPackages

exit


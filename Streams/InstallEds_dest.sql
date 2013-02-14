@defines
set serveroutput on

whenever sqlerror exit;

spool InstallEds_dest.log

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&dest_db_streams_password@&dest_db_url

@@eds_support_install

exit

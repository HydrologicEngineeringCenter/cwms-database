@defines
set serveroutput on

whenever sqlerror exit;

spool UpdatePackages_dest.log

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&dest_db_streams_password@&dest_db_url

@@InstallPackages

exit

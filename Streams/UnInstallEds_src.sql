@defines
set serveroutput on

whenever sqlerror continue;

spool UnIntallEds_src.log

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&source_db_streams_password@&source_db_url

@@eds_support_remove

exit

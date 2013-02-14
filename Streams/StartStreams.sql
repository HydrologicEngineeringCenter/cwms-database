@defines
set serveroutput on

whenever sqlerror exit;

spool StartStreams.log

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&source_db_streams_password@&source_db_url

exec util.start_streams('&source_db_name','&dest_db_name');

exit

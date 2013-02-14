@defines
set serveroutput on

whenever sqlerror exit;

spool create_link_dest.log

PROMPT Connect to source database as &STREAMS_USER

connect &streams_user/&dest_db_streams_password@&dest_db_url

whenever sqlerror continue;

DROP DATABASE LINK &source_db_name;

Whenever sqlerror exit;

CREATE DATABASE LINK &source_db_name CONNECT TO &streams_user IDENTIFIED BY &source_db_streams_password USING '&source_db_url';

exit

@

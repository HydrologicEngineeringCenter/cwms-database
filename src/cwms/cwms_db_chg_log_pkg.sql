set define off
create or replace package cwms_db_chg_log
as
   function get_version (p_application in varchar2 default 'CWMS')
      return varchar2;

end cwms_db_chg_log;
/

SHOW ERRORS;
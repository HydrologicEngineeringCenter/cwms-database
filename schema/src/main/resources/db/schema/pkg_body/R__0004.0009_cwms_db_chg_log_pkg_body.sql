create or replace package body cwms_db_chg_log
as

   function get_version (p_application in varchar2 default 'CWMS')
      return varchar2
   is
      l_application   varchar2(16);
      l_ver_schema    varchar2(64);
      l_ver_data      varchar2(64);
      l_version       varchar2(128);
   begin
      select "version" into l_ver_schema from CWMS_20."flyway_schema_history" a where "version" <> null order by "version" desc;
      select "version" into l_ver_data from CWMS_20."flyway_data_history" a where "version" <> null order by "version" desc;
      l_version := 'schema=' || l_ver_schema || ', data=' || l_ver_data;
      return l_version;
   end;
end cwms_db_chg_log;
/
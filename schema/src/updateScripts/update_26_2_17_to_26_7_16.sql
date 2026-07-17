-------------------
-- general setup --
-------------------
whenever sqlerror exit;
set define on
set verify off
set pages 100
set serveroutput on
define cwms_schema = 'CWMS_20'
define cwms_dba_schema = 'CWMS_DBA'
alter session set current_schema = &cwms_schema;
------------------------------------------------------------
-- spool to file that identifies the database in the name --
------------------------------------------------------------
var db_name varchar2(61)
begin
   select nvl(primary_db_unique_name, db_unique_name) into :db_name from v$database;
end;
/
whenever sqlerror continue;
declare
   l_count pls_integer;
   l_name  varchar2(30);
begin
   select count(*) into l_count from all_objects where object_name = 'CDB_PDBS';
   if l_count > 0 then
      select name
        into l_name
        from v$database;
      :db_name := l_name;
      begin
         select pdb_name
           into l_name
           from cdb_pdbs;
      exception
         when no_data_found then
            l_name := null;
      end;
      if l_name is not null then
         :db_name := :db_name||'-'||l_name;
      end if;
   end if;
end;
/
whenever sqlerror exit;
column db_name new_value db_name
select :db_name as db_name from dual;
define logfile=update_&db_name._26_2_17_to_26_7_16.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------

PROMPT ################################################################################
PROMPT VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./26_07_16/verify_db_version

PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql;

PROMPT ################################################################################
PROMPT REMOVING CRIT FILE SUPPORT
select systimestamp from dual;

@@./26_07_16/remove_crit_file_support

PROMPT ################################################################################
PROMPT REMOVING CWMS_REPORT
select systimestamp from dual;

drop table at_report_templates;

PROMPT ################################################################################
PROMPT REMOVING SCHEDULER AUTH
select systimestamp from dual;

@@./26_07_16/remove_scheduler_auth

PROMPT ################################################################################
PROMPT REMOVING CWMS_ALARM
select systimestamp from dual;

drop package cwms_alarm;
drop public synonym cwms_alarm;
drop table at_alarm;
drop table at_alarm_criteria;
drop table at_alarm_id;

PROMPT ################################################################################
PROMPT REMOVING CWMS_USGS
select systimestamp from dual;

drop package cwms_usgs;
drop public synonym cwms_usgs;

PROMPT ################################################################################
PROMPT ADDING AT_USER_LISTS AND AT_USER_LIST_MEMBERS TABLES 
select systimestamp from dual;

@@./26_07_16/add_at_user_lists

PROMPT ################################################################################
PROMPT ADDING LOCATION_LEVEL VIEWS
select systimestamp from dual;

@@./26_07_16/add_location_level_views

PROMPT ################################################################################
PROMPT UPDATING AT_FCST
select systimestamp from dual;

alter table at_fcst_location rename column primary_location_code to location_code;
alter table at_fcst_location add sort_order number not null;
comment on table at_fcst_location  is 'Holds information on locations for forecasts';
comment on column at_fcst_location.location_code is 'References locations for forecast';
comment on column at_fcst_location.sort_order is 'Sort order for locations (-1 = primary location)';
create unique index at_fcst_location_idx2 on at_fcst_location(
   case when sort_order = -1 then fcst_spec_code end,
   case when sort_order = -1 then sort_order end
);

drop index at_fcst_info_pk;
create unique index at_fcst_info_pk on at_fcst_info(fcst_inst_code, upper(key));
drop index at_fcst_info_idx1;
create index at_fcst_info_idx1 on at_fcst_info(upper(key));

@@../cwms/types/fcst_location_t
@@../cwms/types/fcst_location_tab_t
delete from at_clob where id in ('/VIEWDOCS/AV_FCST_INFO', '/VIEWDOCS/AV_FCST_LOCATION');
@@../cwms/views/av_fcst_info
@@../cwms/views/av_fcst_location

PROMPT ################################################################################
PROMPT CHANGING TS_CODE COLUMNS FROM INTEGER TO NUMBER(14)
select systimestamp from dual;

declare
   l_table_names str_tab_t := str_tab_t(
      'at_cwms_ts_id',
      'at_ts_extents',
      'at_ts_group_assignment');
begin
   for i in 1 .. l_table_names.count loop
      execute immediate 'alter table '||l_table_names(i)||' modify ts_code number(14)';
   end loop;
end;
/

PROMPT ################################################################################
PROMPT CHANGING MEAS_NUMBER COLUMNS FROM VARCHAR2(8) TO VARCHAR2(36)
select systimestamp from dual;

alter table at_streamflow_meas modify meas_number varchar2(36);

PROMPT ################################################################################
PROMPT MODIFYING DATA_ENTRY_DATE COLUMNS TO TIMESTAMP(3)
select systimestamp from dual;

begin
  dbms_rls.enable_policy (
    object_schema => 'cwms_20',
    object_name   => 'at_tsv',
    policy_name   => 'service_user_policy',
    enable        => false
  );
end;
/
alter table at_tsv modify data_entry_date timestamp(3);
begin
  dbms_rls.enable_policy (
    object_schema => 'cwms_20',
    object_name   => 'at_tsv',
    policy_name   => 'service_user_policy',
    enable        => true
  );
end;
/
begin
   for rec in (select table_name from at_ts_table_properties)
   loop
      dbms_rls.enable_policy (
         object_schema => 'cwms_20',
         object_name   => rec.table_name,
         policy_name   => 'service_user_policy',
         enable        => false
      );
      execute immediate 'alter table '||rec.table_name||' modify data_entry_date timestamp(3)';
      dbms_rls.enable_policy (
         object_schema => 'cwms_20',
         object_name   => rec.table_name,
         policy_name   => 'service_user_policy',
         enable        => true
      );
   end loop;
end;
/

-- PROMPT ################################################################################
-- PROMPT ALTERING VIEWS
-- select systimestamp from dual;

PROMPT ################################################################################
PROMPT ALTERING TABLE DATA
select systimestamp from dual;
whenever sqlerror continue;

insert into cwms_base_parameter values (50, 'NBS', 26, 73, 73, 72, 'Net Basin Supply', 'Volume rate of Net Basin Supply to body of water');
insert into cwms_base_parameter values (51, 'NTS', 26, 73, 73, 72, 'Net Total Supply', 'Volume rate of Net Total Supply to body of water');
insert into cwms_base_parameter values (52, 'ProbExceed', 19, 53, 53, 53, 'Probability of Exceedance', 'Ratio expressed as hundredths for Probability of Exceedance');

insert into cwms_error values (-20056, 'CAN_NOT_DELETE_LOC_2', 'Can not delete location: "%1" because dependent data exists: %2');

insert into cwms_sec_user_groups values (6, 'SHOW STACK TRACE', 'Users allowed to receive server stack traces in explicitly enabled debug responses.');

insert into at_parameter values (50, 53, 50, null, 'Net Basin Supply');
insert into at_parameter values (51, 53, 51, null, 'Net Total Supply');
insert into at_parameter values (52, 53, 52, null, 'Probability of Exceedance');

insert into at_ts_category values (11, 'SHEF Export', 53, 'Category for local groups for exporting SHEF data');

insert into at_sec_user_groups values (53, 6, 'SHOW STACK TRACE', 'Users allowed to receive server stack traces in explicitly enabled debug responses.');

whenever sqlerror exit;

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE SPECIFICATIONS
select systimestamp from dual;

drop type streamflow_meas_t force;
@@../cwms/types/streamflow_meas_t
drop type streamflow_meas2_t force;
@@../cwms/types/streamflow_meas2_t

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE BODIES
select systimestamp from dual;

@@../cwms/types/rating_spec_t-body
@@../cwms/types/streamflow_meas_t-body
@@../cwms/types/streamflow_meas2_t-body

PROMPT ################################################################################
PROMPT UPDATING PACKAGE SPECIFICATIONS
select systimestamp from dual;

@@../cwms/cwms_fcst_pkg
@@../cwms/cwms_stream_pkg
@@../cwms/cwms_ts_pkg
@@../cwms/cwms_vt_pkg

PROMPT ################################################################################
PROMPT UPDATING PACKAGE BODIES
select systimestamp from dual;

@@../cwms/cwms_fcst_pkg_body
@@../cwms/cwms_level_pkg_body
@@../cwms/cwms_stream_pkg_body
@@../cwms/cwms_ts_pkg_body
@@../cwms/cwms_vt_pkg_body

-- PROMPT ################################################################################
-- PROMPT UPDATING TRIGGERS
-- select systimestamp from dual;

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@@./util/compile_objects

PROMPT ################################################################################
PROMPT ADDING SEARCH_DOC COLUMN TO AT_PHYSICAL_LOCATION
select systimestamp from dual;

@@./26_07_16/add_search_doc

PROMPT ################################################################################
PROMPT MOVING LATLON TO GEOMETRY
select systimestamp from dual;

@@./26_07_16/update_latlon_to_geometry

PROMPT ################################################################################
PROMPT FINAL HOUSEKEEPING
select systimestamp from dual;

declare
   cmd varchar2(128);
begin
   execute immediate 'grant CWMS_USER to CWMS_DBA';
   for rec in (select object_name,
                      object_type
                 from dba_objects
                where owner = '&cwms_schema'
                  and object_type in ('PACKAGE BODY', 'TYPE', 'VIEW')
                  and object_name not like '%AQ$%'
              )
   loop
      cmd := 'grant '
         ||case when rec.object_type = 'VIEW' then 'select' else 'execute' end
         ||' on &cwms_schema..'
         ||rec.object_name
         ||' to CWMS_USER';
      dbms_output.put(cmd||' [');
      begin
         execute immediate cmd;
         dbms_output.put_line('SUCCEEDED]');
      exception
         when others then dbms_output.put_line('FAILED]');
      end;   
   end loop;
end;
/
PROMPT ################################################################################
PROMPT RESTORING PRE-UPDATE PRIVILEGES
@@./util/restore_privs

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@@./util/compile_objects

promp ################################################################################
PROMPT REMAINING INVALID OBJECTS...
select systimestamp from dual;

select owner||'.'||substr(object_name, 1, 30) as invalid_object,
       object_type
  from all_objects
 where status = 'INVALID'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by 1, 2;
select owner||'.'||substr(name, 1, 30) as name,
       type,
       substr(line||':'||position, 1, 12) as location,
       substr(text, 1, 132) as error
  from all_errors
 where attribute = 'ERROR'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by owner, type, name, sequence;
/

PROMPT ################################################################################
PROMPT ADDING APPROVED QUALITY BIT
select systimestamp from dual;

@@./26_07_16/add_approved_quality_bit


PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA AGAIN

select systimestamp from dual;
@@./util/compile_objects
declare
   l_types str_tab_t;
   l_names str_tab_t;
begin
   select object_type, object_name
     bulk collect
     into l_types, l_names
     from all_objects
    where status = 'INVALID'
      and owner in ('&cwms_schema', '&cwms_dba_schema');

   if l_types.count > 0 then
      dbms_output.put_line(chr(10)||'==>'||chr(10)||'==> THE FOLLOWING OBJECTS ARE STILL INVALID:'||chr(10)||'==>');
      for i in 1..l_types.count loop
         dbms_output.put_line(chr(9)||l_types(i)||' '||l_names(i));
      end loop;
      raise_application_error(-20999, 'There are still invalid objects in the schema. See output above.');
   end if;
end;
/

PROMPT ################################################################################
PROMPT RESTORING PACKGE STATE
select systimestamp from dual;

-- I don't know why this is neccessary.
-- It will fail, but then the state of the packages is no longer discarded.
-- It prevents the following when running ./26_07_16/update_db_change_log:
--     ORA-04068: existing state of packages has been discarded
--     ORA-04061: existing state of package body "CWMS_20.CWMS_UTIL" has been
--     invalidated
--     ORA-04065: not executed, altered or dropped package body "CWMS_20.CWMS_UTIL"
--     Help: https://docs.oracle.com/error-help/db/ora-04068/

whenever sqlerror continue;
select cwms_util.change_timezone(sysdate, 'UTC', 'US/Central') from dual;
whenever sqlerror exit;

PROMPT ################################################################################
PROMPT UPDATING DB_CHANGE_LOG
select systimestamp from dual;

@@./26_07_16/update_db_change_log
select substr(version, 1, 10) as version,
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date,
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;

PROMPT ################################################################################
PROMPT OUTPUT LATLON CONVERSION RESULTS
select systimestamp from dual;

declare
   l_notes  str_tab_t;
   l_counts number_tab_t;
begin
   dbms_output.put_line('Latitude/Longitude to Geometry Conversion Results');
   dbms_output.put_line('================================================================================');
   select conversion_note, count(location_code)
     bulk collect
     into l_notes, l_counts
     from at_latlon_conversion
    group by conversion_note
    order by 2 desc;
   for i in 1..l_notes.count loop
      dbms_output.put_line(to_char(l_counts(i), 99999)||' locations'||chr(9)||l_notes(i));
   end loop;
   dbms_output.put_line(chr(10)||'See table AT_LATLON_CONVERSION for details');
end;
/

PROMPT ################################################################################
PROMPT UPDATE COMPLETE
select systimestamp from dual;
exit

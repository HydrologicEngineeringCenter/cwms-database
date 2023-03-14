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
define logfile=update_&db_name._21_1_x_to_22_1_1.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./22_1_1/verify_db_version

PROMPT ################################################################################
PROMPT REMOVING REMOVE_DEAD_SUBSCRIBERS JOB
select systimestamp from dual;
begin
    dbms_scheduler.drop_job(job_name => '&cwms_schema..remove_dead_subscribers_job',
                            defer => false,
                            force => true);
exception
   when others then
      dbms_output.put_line(sqlerrm);
end;
/
PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TABLES
select systimestamp from dual;
whenever sqlerror continue;
alter table at_loc_lvl_indicator_cond modify comparison_unit number(14) not null;
alter table at_loc_lvl_indicator_cond add constraint at_loc_lvl_indicator_cond_ck8 check (not(rate_expression is not null and rate_comparison_unit is null));

insert into cwms_interval values(60, 'Irr', 0, 'Irregular (alias for 0)');

insert into cwms_duration values(62, 'UntilChanged', -2, 'Duration for const parameter types');
insert into cwms_duration values(61, 'Variable',     -1, 'Variable duration for non-instantaneous or const parameter types');

insert into cwms_parameter_type values(7, 'Cum',    'CUMULATIVE');
insert into cwms_parameter_type values(8, 'Inc',    'INCREMENTAL');
insert into cwms_parameter_type values(8, 'Median', 'MEDIAN');

insert into cwms_abstract_parameter values (35, 'Depth Velocity');

insert into cwms_unit values(130, 'm2/s',  35, 'SI', 'Depth times velocity', 'Depth of 1 meter and Velocity of 1 meter/second');
insert into cwms_unit values(131, 'ft2/s', 35, 'EN', 'Depth times velocity', 'Depth of 1 feet and Velocity of 1 feet/second');
insert into cwms_unit values(132, 'ug',    32, 'SI', 'micrograms',           'Mass of 1 microgram');
insert into cwms_unit values(133, 'ug/l',  18, 'SI', 'micrograms per liter', 'Mass concentration of 1E-06 gram per liter');

insert into at_unit_alias values('DEGF', 53, 68);
insert into at_unit_alias values('micrograms', 53, 132);
insert into at_unit_alias values('micrograms/L', 53, 133);
insert into at_unit_alias values('micrograms/l', 53, 133);

insert into cwms_unit_conversion values('ft2/s',  'ft2/s',  35, 131, 131, 1.0,                   0.0, null);
insert into cwms_unit_conversion values('ft2/s',  'm2/s',   35, 131, 130, 0.09290304,            0.0, null);
insert into cwms_unit_conversion values('g',      'ug',     32, 115, 132, 1000000.0,             0.0, null);
insert into cwms_unit_conversion values('g/l',    'ug/l',   18,  49, 133, 1000000.0,             0.0, null);
insert into cwms_unit_conversion values('gm/cm3', 'ug/l',   18,  50, 133, 1000000000.0,          0.0, null);
insert into cwms_unit_conversion values('kg',     'ug',     32, 116, 132, 1000000000.0,          0.0, null);
insert into cwms_unit_conversion values('lbm',    'ug',     32, 117, 132, 453592370.0,           0.0, null);
insert into cwms_unit_conversion values('m2/s',   'ft2/s',  35, 130, 131, 10.76391041670972,     0.0, null);
insert into cwms_unit_conversion values('m2/s',   'm2/s',   35, 130, 130, 1.0,                   0.0, null);
insert into cwms_unit_conversion values('mg',     'ug',     32, 118, 132, 1000.0,                0.0, null);
insert into cwms_unit_conversion values('mg/l',   'ug/l',   18,  51, 133, 1000.0,                0.0, null);
insert into cwms_unit_conversion values('ppm',    'ug/l',   18,  52, 133, 1000.0,                0.0, null);
insert into cwms_unit_conversion values('ton',    'ug',     32, 119, 132, 907184740000.0,        0.0, null);
insert into cwms_unit_conversion values('tonne',  'ug',     32, 120, 132, 1000000000000.0,       0.0, null);
insert into cwms_unit_conversion values('ug',     'g',      32, 132, 115, 1e-06,                 0.0, null);
insert into cwms_unit_conversion values('ug',     'kg',     32, 132, 116, 1e-09,                 0.0, null);
insert into cwms_unit_conversion values('ug',     'lbm',    32, 132, 117, 2.204622621848776e-09, 0.0, null);
insert into cwms_unit_conversion values('ug',     'mg',     32, 132, 118, 0.001,                 0.0, null);
insert into cwms_unit_conversion values('ug',     'ton',    32, 132, 119, 1.102311310924388e-12, 0.0, null);
insert into cwms_unit_conversion values('ug',     'tonne',  32, 132, 120, 1e-12,                 0.0, null);
insert into cwms_unit_conversion values('ug',     'ug',     32, 132, 132, 1.0,                   0.0, null);
insert into cwms_unit_conversion values('ug/l',   'g/l',    18, 133,  49, 1e-06,                 0.0, null);
insert into cwms_unit_conversion values('ug/l',   'gm/cm3', 18, 133,  50, 1e-09,                 0.0, null);
insert into cwms_unit_conversion values('ug/l',   'mg/l',   18, 133,  51, 0.001,                 0.0, null);
insert into cwms_unit_conversion values('ug/l',   'ppm',    18, 133,  52, 0.001,                 0.0, null);
insert into cwms_unit_conversion values('ug/l',   'ug/l',   18, 133, 133, 1.0,                   0.0, null);

insert into cwms_base_parameter values (49, 'DepthVelocity', 35, 130, 130, 131, 'Depth Velocity', 'Depth Velocity');

insert into at_parameter values(49, 53, 49, null, 'Depth Velocity');

create unique index cwms_time_zone_tnu on cwms_time_zone(upper(time_zone_name));

comment on column at_loc_lvl_indicator_cond.comparison_unit is      'Unit of V, L (or L1), and L2 used for comparisons. Not necessarliy the unit of the expression result';
comment on column at_loc_lvl_indicator_cond.rate_comparison_unit is 'Unit of V, L (or L1), and L2 used for rate comparisons. The numerator unit for R (e.g., ft3 for R in cfs [ft3/s])';

PROMPT ################################################################################
PROMPT CREATING AND ALTERING PACKAGE SPECIFICATIONS
select systimestamp from dual;
@../cwms/cwms_level_pkg
@../cwms/cwms_loc_pkg
@../cwms/cwms_sec_pkg
@../cwms/cwms_sec_policy
@../cwms/cwms_util_pkg
alter session set current_schema = &cwms_dba_schema;
@../cwms_dba/cwms_user_admin_pkg
alter session set current_schema = &cwms_schema;

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE SPECIFICATIONS
select systimestamp from dual;
drop type location_level_t    force;
drop type loc_lvl_indicator_t force;
drop type zlocation_level_t   force;
@../cwms/types/location_level_t
@../cwms/types/loc_lvl_indicator_t
@../cwms/types/zlocation_level_t

PROMPT ################################################################################
PROMPT CREATING AND ALTERING PACKAGE BODIES
select systimestamp from dual;
@../cwms/cwms_display_pkg_body
@../cwms/cwms_level_pkg_body
@../cwms/cwms_loc_pkg_body
@../cwms/cwms_msg_pkg_body
@../cwms/cwms_sec_pkg_body
@../cwms/cwms_sec_policy_body
@../cwms/cwms_ts_pkg_body
@../cwms/cwms_ts_id_pkg_body
@../cwms/cwms_util_pkg_body
alter session set current_schema = &cwms_dba_schema;
@../cwms_dba/cwms_user_admin_pkg_body
alter session set current_schema = &cwms_schema;

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE BODIES
select systimestamp from dual;
@../cwms/types/location_level_t-body;
@../cwms/types/loc_lvl_indicator_cond_t-body;
@../cwms/types/loc_lvl_indicator_t-body;
@../cwms/types/zlocation_level_t-body;

PROMPT ################################################################################
PROMPT CREATING AND ALTERING VIEWS
select systimestamp from dual;
delete from at_clob where id = '/VIEWDOCS/AV_TSV';
delete from at_clob where id = '/VIEWDOCS/AV_TSV_DQU';
delete from at_clob where id = '/VIEWDOCS/AV_TSV_DQU_30D';
delete from at_clob where id = '/VIEWDOCS/AV_TSV_DQU_24H';
delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL';
delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL2';
delete from at_clob where id = '/VIEWDOCS/AV_PARAMETER_TYPE';
delete from at_clob where id = '/VIEWDOCS/AV_VIRTUAL_LOCATION_LEVEL';
delete from at_clob where id = '/VIEWDOCS/AV_VLOC_LVL_CONSTITUENT';
@../cwms/at_schema_tsv_dqu
@../cwms/views/av_location_level
@../cwms/views/av_location_level2
@../cwms/views/av_parameter_type
@../cwms/views/av_virtual_location_level
@../cwms/views/av_vloc_lvl_constituent
create or replace public synonym CWMS_V_PARAMETER_TYPE for AV_PARAMETER_TYPE;

PROMPT ################################################################################
PROMPT INVALID OBJECTS...
select systimestamp from dual;
set pagesize 100
select owner||'.'||substr(object_name, 1, 30) as invalid_object,
       object_type
  from all_objects
 where status = 'INVALID'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by 1, 2;

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects

PROMPT ################################################################################
PROMPT UPDATING USER POLICIES (INCLUDING HIDING NEW CWMS DATA VALUES)
@../cwms/create_user_policies

PROMPT ################################################################################
PROMPT REMOVING FUNCTIONS AND PROCEDURES
drop function check_session_user;
drop procedure remove_dead_subscribers;

PROMPT ################################################################################
PROMPT REINSTATING ENTITIES
select systimestamp from dual;
@../cwms/create_sec_triggers
@../cwms/at_tsv_count_trig
@../cwms/at_dd_flag_trig

promp ################################################################################
PROMPT FINAL HOUSEKEEPING
select systimestamp from dual;
declare
   type usernames_t is table of varchar2(30);
   usernames usernames_t;
   l_count integer;
   cmd varchar2(128);
begin
   select count(*) into l_count from dba_users where username='CCP';
   usernames := usernames_t('&cwms_schema', '&cwms_dba_schema');
   if (l_count > 0) then
      usernames.extend;
      usernames(usernames.count) := 'CCP';
   end if;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'PACKAGE BODY') loop
      cmd := 'grant execute on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'TYPE') loop
      cmd := 'grant execute on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'VIEW' and object_name not like '%AQ$%') loop
      cmd := 'grant select on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
end;
/
@@./util/restore_privs
exec cwms_msg.start_remove_subscribers_job()

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects

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

whenever sqlerror exit;

PROMPT ################################################################################
PROMPT UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./22_1_1/update_db_change_log
select substr(version, 1, 10) as version,
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date,
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;
declare
   l_count pls_integer;
begin
   select count(*)
     into l_count
     from all_objects
    where status = 'INVALID'
      and owner in ('&cwms_schema', '&cwms_dba_schema');

   if l_count > 0 then
      raise_application_error(-20999, chr(10)||'==>'||chr(10)||'==> SOME OBJECTS ARE STILL INVALID'||chr(10)||'==>');
   end if;
end;
/
PROMPT ################################################################################
PROMPT UPDATE COMPLETE
select systimestamp from dual;
exit

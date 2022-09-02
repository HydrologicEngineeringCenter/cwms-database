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

PROMPT ********** store existing privileges to non-CWMS users
@@./util/preupdate_privs.sql

PROMPT ********** Update cwms tables
@@./22_1_1/update_cwms_tables

PROMPT ********** Alter table(s)
whenever sqlerror continue;
ALTER TABLE AT_LOC_LVL_INDICATOR_COND DROP CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK8;
whenever sqlerror exit;
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE AT_LOC_LVL_INDICATOR_COND MODIFY(COMPARISON_UNIT  NOT NULL)';
EXCEPTION
    WHEN OTHERS
    THEN
        IF SQLCODE = -1442
        THEN
            DBMS_OUTPUT.PUT_LINE ('Column is already set to not null');
            NULL;     
        ELSE
            RAISE;
        END IF;
END;
/
ALTER TABLE AT_LOC_LVL_INDICATOR_COND
 ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK8
  CHECK (NOT(RATE_EXPRESSION IS NOT NULL AND RATE_COMPARISON_UNIT IS NULL));

PROMPT ********** Add/update comments
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.COMPARISON_UNIT IS 'Unit of V, L (or L1), and L2 used for comparisons. Not necessarliy the unit of the expression result';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_COMPARISON_UNIT IS 'Unit of V, L (or L1), and L2 used for rate comparisons. The numerator unit for R (e.g., ft3 for R in cfs [ft3/s])';

PROMPT ********** Build new index for CWMS_TIME_ZONE
whenever sqlerror continue;
DROP INDEX CWMS_TIME_ZONE_TNU;
whenever sqlerror exit;
CREATE UNIQUE INDEX CWMS_TIME_ZONE_TNU ON CWMS_TIME_ZONE(UPPER("TIME_ZONE_NAME"));

-----------
-- VIEWS --
-----------
PROMPT ********** Updating views

delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL';
@../cwms/views/av_location_level
delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL2';
@../cwms/views/av_location_level2
delete from at_clob where id = '/VIEWDOCS/AV_PARAMETER_TYPE';
@../cwms/views/av_parameter_type
delete from at_clob where id = '/VIEWDOCS/AV_VIRTUAL_LOCATION_LEVEL';
@../cwms/views/av_virtual_location_level
delete from at_clob where id = '/VIEWDOCS/AV_VLOC_LVL_CONSTITUENT';
@../cwms/views/av_vloc_lvl_constituent
commit;

-------------------
-- PACKAGE SPECS --
-------------------
PROMPT ********** update package specs

@../cwms/cwms_level_pkg
@../cwms/cwms_loc_pkg
@../cwms/cwms_sec_pkg
@../cwms/cwms_sec_policy
@../cwms/cwms_util_pkg

----------------
-- TYPE SPECS --
----------------
PROMPT ********** update type specs

drop type location_level_t force;
@../cwms/types/location_level_t
drop type loc_lvl_indicator_t force;
@../cwms/types/loc_lvl_indicator_t
drop type zlocation_level_t; 
@../cwms/types/zlocation_level_t

----------------
-- TYPE BODY --
----------------
PROMPT ********** update type bodies

@../cwms/types/location_level_t-body
@../cwms/types/loc_lvl_indicator_cond_t-body
@../cwms/types/loc_lvl_indicator_t-body
@../cwms/types/zlocation_level_t-body
--------------------
-- PACKAGE BODIES --
--------------------
PROMPT ********** update package bodies

@../cwms/cwms_display_pkg_body
@../cwms/cwms_level_pkg_body
@../cwms/cwms_loc_pkg_body
@../cwms/cwms_msg_pkg_body
@../cwms/cwms_sec_pkg_body
@../cwms/cwms_sec_policy_body
@../cwms/cwms_ts_pkg_body
@../cwms/cwms_ts_id_pkg_body
@../cwms/cwms_util_pkg_body

PROMPT ********** Drop objects
whenever sqlerror continue;
drop function check_session_user;
drop procedure remove_dead_subscribers;
whenever sqlerror exit;

PROMPT ********** Grant pemissions

grant execute on location_level_t to cwms_user;
grant execute on loc_lvl_indicator_t to cwms_user;
grant execute on zlocation_level_t to cwms_user;
grant select on av_parameter_type to cwms_user;


PROMPT ********** Drop application triggers for read only users 

BEGIN
    FOR c
        IN (SELECT *
              FROM dba_objects
             WHERE     owner = '&cwms_schema'
                   AND object_type = 'TRIGGER'
                   AND object_name IN
                           ('ST_APPLICATION_LOGIN', 'ST_APPLICATION_SESSION'))
    LOOP
        DBMS_OUTPUT.PUT_LINE ('drop trigger ' || c.object_name);
        EXECUTE IMMEDIATE 'drop trigger ' || c.object_name;
    END LOOP;
END;
/

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
PROMPT ********** RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects
PROMPT ********** retstart remove subscribers job
exec cwms_msg.start_remove_subscribers_job()
PROMPT ********** create user policies
@../cwms/create_user_policies.sql
PROMPT ********** create read only triggers
@../cwms/create_sec_triggers
PROMPT ********** RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects
PROMPT ################################################################################
PROMPT ********** REMAINING INVALID OBJECTS...
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
PROMPT ################################################################################
PROMPT ********** restore non-CWMS objects privileges
select systimestamp from dual;
whenever sqlerror continue;
@@./util/restore_privs
whenever sqlerror exit;
PROMPT ################################################################################
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
PROMPT ################################################################################
PROMPT ********** UPDATE COMPLETE
select systimestamp from dual;
exit


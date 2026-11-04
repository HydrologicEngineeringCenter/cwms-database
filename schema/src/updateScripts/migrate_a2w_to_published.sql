/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

--------------------------------------------------------------------------------
-- Migrates AT_A2W_TS_CODES_BY_LOC into the normalized tables defined in
-- at_published.sql and at_a2w_attributes.sql:
--
--   AT_A2W_ATTRIBUTES   - app-specific display/notes metadata, 1:1 by LOCATION_CODE
--   AT_PUBLISHED_TS     - one row per non-null TS_CODE_* column
--   AT_PUBLISHED_RATING - one row per non-null RATING_CODE_* column
--
-- How to run: in SQL*Plus or SQLcl, as (or with current_schema set to) the CWMS
-- schema, while CMA is not in use. Run it standalone, not from inside a larger
-- script, so the review step at the end means something.
--
-- Sections:
--   0. Setup (DDL). All DDL is here, before any data is changed, because DDL
--      commits implicitly. Creates the error-log tables, a work table holding the
--      unpivoted source rows, and a backup table for object-sourced openings.
--   1. Dry-run report: what will migrate, and what will be skipped or rejected
--      and why. Nothing has been changed yet.
--   2. Migration (DML only, one transaction). Bad rows are logged to the ERR$_
--      tables instead of aborting the run.
--   3. Reconciliation: source vs migrated counts per published ID, and the rows
--      rejected by this run.
--   4. Nothing is committed. Review sections 1 and 3, then COMMIT or ROLLBACK.
--      Note: SQL*Plus commits on a normal EXIT unless you ROLLBACK first.
--
-- Safe to rerun: every insert skips rows that are already in the target table,
-- and each run tags its error-log rows with its own run tag.
--
-- Known gap: when OPENING_SOURCE_OBJ = OBJ, TS_CODE_OPENING holds an object
-- reference, not a TS_CODE, so it cannot go into AT_PUBLISHED_TS (it would fail
-- AT_PUBLISHED_TS_FK_TS / AT_PUBLISHED_TS_T01). OPENING_SOURCE_OBJ is kept on
-- AT_A2W_ATTRIBUTES, and the object codes are saved to A2W_OPENING_OBJ_BACKUP so
-- they survive the eventual drop of AT_A2W_TS_CODES_BY_LOC.
--------------------------------------------------------------------------------
set define on
set verify off
set linesize 200
set pagesize 200
column ora_err_mesg$ format a80 word_wrapped
column reason format a60

column run_tag new_value run_tag noprint
select 'A2W_MIGRATION_' || to_char(sysdate, 'YYYYMMDD_HH24MISS') as run_tag from dual;
prompt Run tag for this migration: &run_tag

--------------------------------------------------------------------------------
-- 0. Setup (DDL only)
--------------------------------------------------------------------------------

-- Error-log tables (created once, reused by later runs). NOTES is a CLOB, which
-- error logging cannot record, so it is left out of ERR$_AT_A2W_ATTRIBUTES.
begin
   for rec in (select 'AT_A2W_ATTRIBUTES' as table_name from dual
               union all select 'AT_PUBLISHED_TS' from dual
               union all select 'AT_PUBLISHED_RATING' from dual)
   loop
      begin
         dbms_errlog.create_error_log(
            dml_table_name   => rec.table_name,
            skip_unsupported => true);
      exception
         when others then
            if sqlcode != -955 then -- ORA-00955: name already used by an existing object
               raise;
            end if;
      end;
   end loop;
end;
/

-- Backup of object-sourced opening codes (created once; rows added in section 2).
begin
   execute immediate '
      create table a2w_opening_obj_backup (
         location_code number(14) not null,
         opening_code  number     not null,
         backed_up_on  date       default sysdate not null,
         constraint a2w_opening_obj_backup_pk primary key (location_code)
      ) tablespace cwms_20at_data';
exception
   when others then
      if sqlcode != -955 then
         raise;
      end if;
end;
/

-- Work table: one row per non-null code in the old wide table, rebuilt every run.
-- Sections 1, 2 and 3 all read this, so the unpivot is written only once.
begin
   execute immediate 'drop table a2w_migration_source purge';
exception
   when others then
      if sqlcode != -942 then -- ORA-00942: table or view does not exist
         raise;
      end if;
end;
/

create table a2w_migration_source tablespace cwms_20at_data as
select kind, location_code, published_id, code, opening_source_obj
  from (
      select cast('TS' as varchar2(6)) as kind, location_code, cast('TS_ELEV' as varchar2(24)) as published_id, ts_code_elev as code, upper(trim(opening_source_obj)) as opening_source_obj from at_a2w_ts_codes_by_loc where ts_code_elev is not null
      union all select 'TS', location_code, 'TS_PRECIP',          ts_code_precip,          upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_precip          is not null
      union all select 'TS', location_code, 'TS_STAGE',           ts_code_stage,           upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_stage           is not null
      union all select 'TS', location_code, 'TS_INFLOW',          ts_code_inflow,          upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_inflow          is not null
      union all select 'TS', location_code, 'TS_OUTFLOW',         ts_code_outflow,         upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_outflow         is not null
      union all select 'TS', location_code, 'TS_STOR_FLOOD',      ts_code_stor_flood,      upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_stor_flood      is not null
      union all select 'TS', location_code, 'TS_STOR_DROUGHT',    ts_code_stor_drought,    upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_stor_drought    is not null
      union all select 'TS', location_code, 'TS_SUR_RELEASE',     ts_code_sur_release,     upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_sur_release     is not null
      union all select 'TS', location_code, 'TS_ELEV_TW',         ts_code_elev_tw,         upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_elev_tw         is not null
      union all select 'TS', location_code, 'TS_STAGE_TW',        ts_code_stage_tw,        upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_stage_tw        is not null
      union all select 'TS', location_code, 'TS_RULE_CURVE_ELEV', ts_code_rule_curve_elev, upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_rule_curve_elev is not null
      union all select 'TS', location_code, 'TS_POWER_GEN',       ts_code_power_gen,       upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_power_gen       is not null
      union all select 'TS', location_code, 'TS_TEMP_AIR',        ts_code_temp_air,        upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_temp_air        is not null
      union all select 'TS', location_code, 'TS_TEMP_WATER',      ts_code_temp_water,      upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_temp_water      is not null
      union all select 'TS', location_code, 'TS_DO',              ts_code_do,              upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_do              is not null
      union all select 'TS', location_code, 'TS_COND',            ts_code_cond,            upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_cond            is not null
      union all select 'TS', location_code, 'TS_PH',              ts_code_ph,              upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_ph              is not null
      union all select 'TS', location_code, 'TS_OPENING',         ts_code_opening,         upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_opening         is not null
      union all select 'TS', location_code, 'TS_WIND_DIR',        ts_code_wind_dir,        upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_wind_dir        is not null
      union all select 'TS', location_code, 'TS_WIND_SPEED',      ts_code_wind_speed,      upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_wind_speed      is not null
      union all select 'TS', location_code, 'TS_VOLT',            ts_code_volt,            upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_volt            is not null
      union all select 'TS', location_code, 'TS_PCT_FLOOD',       ts_code_pct_flood,       upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_pct_flood       is not null
      union all select 'TS', location_code, 'TS_PCT_CON',         ts_code_pct_con,         upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_pct_con         is not null
      union all select 'TS', location_code, 'TS_IRRAD',           ts_code_irrad,           upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_irrad           is not null
      union all select 'TS', location_code, 'TS_EVAP',            ts_code_evap,            upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where ts_code_evap            is not null
      union all select 'RATING', location_code, 'RATING_ELEV_STOR',   rating_code_elev_stor,   upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where rating_code_elev_stor   is not null
      union all select 'RATING', location_code, 'RATING_ELEV_AREA',   rating_code_elev_area,   upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where rating_code_elev_area   is not null
      union all select 'RATING', location_code, 'RATING_OUTLET_FLOW', rating_code_outlet_flow, upper(trim(opening_source_obj)) from at_a2w_ts_codes_by_loc where rating_code_outlet_flow is not null
  );

--------------------------------------------------------------------------------
-- 1. Dry-run report (read only)
--------------------------------------------------------------------------------

prompt
prompt ==== 1a. What will happen to each mapping, by published ID and reason ====
select kind, published_id, reason, count(*) as row_count
  from (
      select s.kind,
             s.published_id,
             case
                when s.published_id = 'TS_OPENING' and nvl(s.opening_source_obj, 'TS') = 'OBJ'
                   then 'skip: opening is an object reference (saved to backup)'
                when s.kind = 'TS' and exists (select 1 from at_published_ts t
                                                where t.location_code = s.location_code
                                                  and t.published_id  = s.published_id
                                                  and t.ts_code       = s.code)
                   then 'skip: already migrated'
                when s.kind = 'RATING' and exists (select 1 from at_published_rating r
                                                    where r.location_code    = s.location_code
                                                      and r.published_id     = s.published_id
                                                      and r.rating_spec_code = s.code)
                   then 'skip: already migrated'
                when p.published_id is null
                   then 'reject: published ID missing from CWMS_PUBLISHED_ID'
                when s.kind = 'TS' and ts.ts_code is null
                   then 'reject: ts_code no longer exists'
                when s.kind = 'RATING' and rs.rating_spec_code is null
                   then 'reject: rating_spec_code no longer exists'
                when s.kind = 'TS' and nvl(tsp.base_parameter_code, -1) != p.base_parameter_code
                   then 'reject: base parameter does not match published ID'
                when s.kind = 'RATING' and nvl(rtp.base_parameter_code, -1) != p.base_parameter_code
                   then 'reject: base parameter does not match published ID'
                when s.kind = 'TS' and ts.delete_date is not null
                   then 'ok (time series is marked deleted)'
                else 'ok'
             end as reason
        from a2w_migration_source s
        left join cwms_published_id  p   on p.published_id = s.published_id
        left join at_cwms_ts_spec    ts  on s.kind = 'TS' and ts.ts_code = s.code
        left join at_parameter       tsp on tsp.parameter_code = ts.parameter_code
        left join at_rating_spec     rs  on s.kind = 'RATING' and rs.rating_spec_code = s.code
        left join at_rating_template rt  on rt.template_code = rs.template_code
        left join at_parameter       rtp on rtp.parameter_code = rt.dep_parameter_code
  )
 group by kind, published_id, reason
 order by kind, published_id, reason;

prompt
prompt ==== 1b. Attribute rows whose flags will fail the new CHECK constraints ====
prompt (values are trimmed and upper-cased first; anything still invalid is rejected)
select location_code, display_flag, lake_summary_tf, opening_source_obj
  from at_a2w_ts_codes_by_loc
 where nvl(upper(trim(display_flag)), '?') not in ('T', 'F')
    or nvl(upper(trim(lake_summary_tf)), '?') not in ('T', 'F')
    or upper(trim(opening_source_obj)) not in ('OBJ', 'TS');

--------------------------------------------------------------------------------
-- 2. Migration (DML only - one transaction, nothing committed)
--------------------------------------------------------------------------------

prompt
prompt ==== 2. Migrating ====

-- 2a. Object-sourced opening codes -> backup table
insert into a2w_opening_obj_backup (location_code, opening_code)
select o.location_code, o.ts_code_opening
  from at_a2w_ts_codes_by_loc o
 where o.ts_code_opening is not null
   and upper(trim(o.opening_source_obj)) = 'OBJ'
   and not exists (select 1 from a2w_opening_obj_backup b where b.location_code = o.location_code);

-- 2b. AT_A2W_ATTRIBUTES (1:1 copy, flags trimmed and upper-cased)
insert into at_a2w_attributes (location_code, date_refreshed, notes, display_flag, lake_summary_tf, opening_source_obj)
select o.location_code,
       o.date_refreshed,
       o.notes,
       upper(trim(o.display_flag)),
       upper(trim(o.lake_summary_tf)),
       upper(trim(o.opening_source_obj))
  from at_a2w_ts_codes_by_loc o
 where not exists (select 1 from at_a2w_attributes a where a.location_code = o.location_code)
log errors into err$_at_a2w_attributes ('&run_tag') reject limit unlimited;

-- 2c. AT_PUBLISHED_TS (object-sourced openings excluded - see known gap above)
insert into at_published_ts (location_code, published_id, ts_code)
select s.location_code, s.published_id, s.code
  from a2w_migration_source s
 where s.kind = 'TS'
   and not (s.published_id = 'TS_OPENING' and nvl(s.opening_source_obj, 'TS') = 'OBJ')
   and not exists (select 1 from at_published_ts t
                    where t.location_code = s.location_code
                      and t.published_id  = s.published_id
                      and t.ts_code       = s.code)
log errors into err$_at_published_ts ('&run_tag') reject limit unlimited;

-- 2d. AT_PUBLISHED_RATING
insert into at_published_rating (location_code, published_id, rating_spec_code)
select s.location_code, s.published_id, s.code
  from a2w_migration_source s
 where s.kind = 'RATING'
   and not exists (select 1 from at_published_rating r
                    where r.location_code    = s.location_code
                      and r.published_id     = s.published_id
                      and r.rating_spec_code = s.code)
log errors into err$_at_published_rating ('&run_tag') reject limit unlimited;

--------------------------------------------------------------------------------
-- 3. Reconciliation
--------------------------------------------------------------------------------

prompt
prompt ==== 3a. Source rows vs rows now in the new tables, per published ID ====
prompt (object-sourced openings are not counted; they are in A2W_OPENING_OBJ_BACKUP)
select kind, published_id, count(*) as source_rows, sum(in_new_table) as in_new_table
  from (
      select s.kind,
             s.published_id,
             case
                when s.kind = 'TS' and exists (select 1 from at_published_ts t
                                                where t.location_code = s.location_code
                                                  and t.published_id  = s.published_id
                                                  and t.ts_code       = s.code)
                   then 1
                when s.kind = 'RATING' and exists (select 1 from at_published_rating r
                                                    where r.location_code    = s.location_code
                                                      and r.published_id     = s.published_id
                                                      and r.rating_spec_code = s.code)
                   then 1
                else 0
             end as in_new_table
        from a2w_migration_source s
       where not (s.published_id = 'TS_OPENING' and nvl(s.opening_source_obj, 'TS') = 'OBJ')
  )
 group by kind, published_id
 order by kind, published_id;

prompt
prompt ==== 3b. Attribute rows: source vs AT_A2W_ATTRIBUTES ====
select (select count(*) from at_a2w_ts_codes_by_loc) as source_rows,
       (select count(*)
          from at_a2w_ts_codes_by_loc o
         where exists (select 1 from at_a2w_attributes a where a.location_code = o.location_code)) as in_new_table
  from dual;

prompt
prompt ==== 3c. Rows rejected by this run ====
select ora_err_mesg$, location_code, display_flag, lake_summary_tf, opening_source_obj
  from err$_at_a2w_attributes
 where ora_err_tag$ = '&run_tag';

select ora_err_mesg$, location_code, published_id, ts_code
  from err$_at_published_ts
 where ora_err_tag$ = '&run_tag';

select ora_err_mesg$, location_code, published_id, rating_spec_code
  from err$_at_published_rating
 where ora_err_tag$ = '&run_tag';

--------------------------------------------------------------------------------
-- 4. Review, then COMMIT or ROLLBACK
--------------------------------------------------------------------------------
prompt
prompt ==== Nothing has been committed. ====
prompt Review sections 1 and 3, then run COMMIT or ROLLBACK.
prompt SQL*Plus commits on a normal EXIT, so ROLLBACK first if you want to discard.

-- After COMMIT or ROLLBACK, the work table and error logs can be dropped
-- (each DROP commits, so do not run these before deciding):
--    drop table a2w_migration_source purge;
--    drop table err$_at_a2w_attributes purge;
--    drop table err$_at_published_ts purge;
--    drop table err$_at_published_rating purge;
-- Keep A2W_OPENING_OBJ_BACKUP until the object-sourced opening codes have a home
-- in the new schema.

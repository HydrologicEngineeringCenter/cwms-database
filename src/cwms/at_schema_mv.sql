@@defines.sql

declare
   type id_array_t is table of varchar2(32);

   mview_names id_array_t := id_array_t(
      'mv_cwms_ts_id'
   );
begin                
   for i in mview_names.first .. mview_names.last loop
      begin 
         execute immediate 'drop materialized view ' || mview_names(i);
         dbms_output.put_line('Dropped materialized view ' || mview_names(i));
      exception 
         when others then null;
      end;
   end loop;
end;
/
-------------------------
-- MV_CWMS_TS_ID view.
-- 
CREATE MATERIALIZED VIEW LOG ON at_base_location     WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON at_physical_location WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON at_cwms_ts_spec      WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_office          WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_parameter_type  WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_base_parameter  WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON at_parameter         WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_interval        WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_duration        WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_unit            WITH ROWID;
CREATE MATERIALIZED VIEW LOG ON cwms_abstract_parameter            WITH ROWID;



CREATE MATERIALIZED VIEW "&cwms_schema"."MV_CWMS_TS_ID" 
TABLESPACE CWMS_20AT_DATA
NOCACHE
LOGGING
NOCOMPRESS
NOPARALLEL
BUILD IMMEDIATE
REFRESH FAST ON DEMAND
WITH PRIMARY KEY
AS 
SELECT abl.db_office_code, abl.base_location_code,
       s.location_code,
       l.active_flag loc_active_flag,
       ap.parameter_code, s.ts_code, s.active_flag ts_active_flag,
       CASE
          WHEN l.active_flag = 'T'
          AND s.active_flag = 'T'
             THEN 'T'
          ELSE 'F'
       END net_ts_active_flag,
       o.office_id db_office_id,
          abl.base_location_id
       || SUBSTR ('-', 1, LENGTH (l.sub_location_id))
       || l.sub_location_id
       || '.'
       || base_parameter_id
       || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id))
       || ap.sub_parameter_id
       || '.'
       || parameter_type_id
       || '.'
       || interval_id
       || '.'
       || duration_id
       || '.'
       || VERSION cwms_ts_id,
       u.unit_id, cap.abstract_param_id,  abl.base_location_id,
       l.sub_location_id,
          abl.base_location_id
       || SUBSTR ('-', 1, LENGTH (l.sub_location_id))
       || l.sub_location_id location_id,
       base_parameter_id, ap.sub_parameter_id,
          base_parameter_id
       || SUBSTR ('-', 1, LENGTH (ap.sub_parameter_id))
       || ap.sub_parameter_id parameter_id,
       parameter_type_id, interval_id, duration_id, VERSION version_id,
       i.INTERVAL, s.interval_utc_offset, s.version_flag,
       abl.ROWID "base_loc_rid", o.ROWID "cwms_office_rid",
       l.ROWID "phys_loc_rid", s.ROWID "ts_spec_rid",
       p.ROWID "base_param_rid", ap.ROWID "param_rid",
       t.ROWID "param_type_rid", i.ROWID "interval_rid",
       d.ROWID "duration_rid", u.ROWID "unit_rid", cap.ROWID "ab_param_rid"
  FROM cwms_office o,
       at_base_location abl,
       at_physical_location l,
       at_cwms_ts_spec s,
       at_parameter ap,
       cwms_base_parameter p,
       cwms_parameter_type t,
       cwms_interval i,
       cwms_duration d,
       cwms_unit u,
       cwms_abstract_parameter cap
 WHERE abl.db_office_code = o.office_code
   AND l.location_code = s.location_code
   AND ap.base_parameter_code = p.base_parameter_code
   AND s.parameter_code = ap.parameter_code
   AND s.parameter_type_code = t.parameter_type_code
   AND s.interval_code = i.interval_code
   AND s.duration_code = d.duration_code
   AND u.unit_code = p.unit_code
   AND u.abstract_param_code = cap.abstract_param_code
   AND l.base_location_code = abl.base_location_code
   AND s.delete_date IS NULL;

SET define on
COMMENT ON MATERIALIZED VIEW "&cwms_schema"."MV_CWMS_TS_ID" IS 'snapshot table for snapshot MV_CWMS_TS_ID';


CREATE  INDEX "&cwms_schema"."MV_CWMS_TS_ID_UK1" ON "&cwms_schema"."MV_CWMS_TS_ID"
(UPPER("DB_OFFICE_ID"), UPPER("CWMS_TS_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
NOPARALLEL;

CREATE  INDEX "&cwms_schema"."MV_CWMS_TS_ID_PK" ON "&cwms_schema"."MV_CWMS_TS_ID"
(DB_OFFICE_ID, CWMS_TS_ID)
LOGGING
TABLESPACE CWMS_20AT_DATA
NOPARALLEL;

CREATE  INDEX "&cwms_schema"."MV_CWMS_TS_ID_UK2" ON "&cwms_schema"."MV_CWMS_TS_ID"
(TS_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
NOPARALLEL;






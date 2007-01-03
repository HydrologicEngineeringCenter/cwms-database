/* CWMS Version 2.0 
This script should be run by the cwms schema owner.
*/ 
exec cwms_util.create_view
/
show errors;

CREATE OR REPLACE VIEW AV_TSV_DQU
(TS_CODE, VERSION_DATE, DATA_ENTRY_DATE, DATE_TIME, VALUE, 
 OFFICE_ID, UNIT_ID, CWMS_TS_ID, QUALITY_CODE, START_DATE, 
 END_DATE)
AS 
select tsv.ts_code,
       tsv.version_date,
       tsv.data_entry_date,
       tsv.date_time,
       tsv.value*c.factor+c.offset  value,
       ts.db_office_id office_id,
       c.to_unit_id unit_id,
       ts.cwms_ts_id,
       tsv.quality_code,
       tsv.start_date,
       tsv.end_date
from av_tsv               tsv,
     mv_cwms_ts_id        ts,
     cwms_unit_conversion c
 where
     tsv.ts_code    = ts.ts_code
 and ts.unit_id     = c.from_unit_id
/ 

/* CWMS Version 2.0 
This script should be run by the cwms schema owner.
*/ 
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV', null,
'
/**
 * Displays time series times, values, and quality in database storage units
 *
 * @since CWMS 2.1
 *
 * @see view av_tsv_dqu
 * @see view mv_data_quality
 * @see cwms_util.non_versioned
 *
 * @field ts_code         Unique numeric code identifying the time series
 * @field date_time       The date/time (in UTC) of the time series value
 * @field version_date    The version date of the time series
 * @field data_entry_date The date/time (in UTC) that the time series value was inserted or updated
 * @field value           The time series value, in database storage units
 * @field quality_code    The quality code associated with the time series value
 * @field start_date      The start date of the underlying table holding the time series value
 * @field end_date        The end date of the underlying table holding the time series value
 */
');
exec cwms_util.create_view;
show errors;

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV_DQU', null,
'
/**
 * Displays time series times, values, and quality in every valid unit
 *
 * @since CWMS 2.1
 *
 * @see view av_tsv
 * @see view mv_data_quality
 * @see cwms_util.non_versioned
 *
 * @field ts_code         Unique numeric code identifying the time series
 * @field version_date    The version date of the time series
 * @field data_entry_date The date/time (in UTC) that the time series value was inserted or updated
 * @field date_time       The date/time (in UTC) of the time series value
 * @field value           The time series value, in the specified unit
 * @field office_id       The office owning the time series
 * @field unit_id         The unit of the time series value
 * @field cwms_ts_id      The time series identifier
 * @field quality_code    The quality code associated with the time series value
 * @field start_date      The start date of the underlying table holding the time series value
 * @field end_date        The end date of the underlying table holding the time series value
 */
');

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

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV_DQU_30D', null,
'
/**
 * Displays time series times, values, and quality in every valid unit for most recent 30 days
 *
 * @since CWMS 2.1
 *
 * @see view av_tsv
 * @see view mv_data_quality
 * @see cwms_util.non_versioned
 *
 * @field ts_code         Unique numeric code identifying the time series
 * @field version_date    The version date of the time series
 * @field data_entry_date The date/time (in UTC) that the time series value was inserted or updated
 * @field date_time       The date/time (in UTC) of the time series value
 * @field value           The time series value, in the specified unit
 * @field office_id       The office owning the time series
 * @field unit_id         The unit of the time series value
 * @field cwms_ts_id      The time series identifier
 * @field quality_code    The quality code associated with the time series value
 * @field start_date      The start date of the underlying table holding the time series value
 * @field end_date        The end date of the underlying table holding the time series value
 */
');

CREATE OR REPLACE VIEW AV_TSV_DQU_30D
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
 and tsv.date_time >= sysdate - 30
/ 

insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV_DQU_24H', null,
'
/**
 * Displays time series times, values, and quality in every valid unit for most recent 24 hours
 *
 * @since CWMS 2.1
 *
 * @see view av_tsv
 * @see view mv_data_quality
 * @see cwms_util.non_versioned
 *
 * @field ts_code         Unique numeric code identifying the time series
 * @field version_date    The version date of the time series
 * @field data_entry_date The date/time (in UTC) that the time series value was inserted or updated
 * @field date_time       The date/time (in UTC) of the time series value
 * @field value           The time series value, in the specified unit
 * @field office_id       The office owning the time series
 * @field unit_id         The unit of the time series value
 * @field cwms_ts_id      The time series identifier
 * @field quality_code    The quality code associated with the time series value
 * @field start_date      The start date of the underlying table holding the time series value
 * @field end_date        The end date of the underlying table holding the time series value
 */
');

CREATE OR REPLACE VIEW AV_TSV_DQU_24H
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
 and tsv.date_time >= sysdate - 1
/ 


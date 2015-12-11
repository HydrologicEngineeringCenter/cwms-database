insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_SCREENING_CONTROL', null,
'
/**
 * [description needed]
 *
 * @since CWMS 3.0
 *
 * @field screening_code               [description needed]
 * @field db_office_id                 [description needed]
 * @field screening_id                 [description needed]
 * @field range_active_flag            [description needed]
 * @field rate_change_active_flag     [description needed]
 * @field const_active_flag            [description needed]
 * @field dur_mag_active_flag            [description needed]
 * @field rate_change_disp_interval_id    [description needed]
 */
');
CREATE OR REPLACE FORCE VIEW AV_SCREENING_CONTROL
(
   SCREENING_CODE,
   DB_OFFICE_ID,
   SCREENING_ID,
   RANGE_ACTIVE_FLAG,
   RATE_CHANGE_ACTIVE_FLAG,
   CONST_ACTIVE_FLAG,
   DUR_MAG_ACTIVE_FLAG,
   RATE_CHANGE_DISP_INTERVAL_ID
)
AS
   SELECT atsi.screening_code,
          co.office_id db_office_id,
          atsi.screening_id,
          asctl.range_active_flag,
          asctl.rate_change_active_flag,
          asctl.const_active_flag,
          asctl.dur_mag_active_flag,
          ci.interval_id rate_change_disp_interval_id
     FROM at_screening_id atsi,
          cwms_office co,
          cwms_interval ci,
          at_screening_control asctl
    WHERE     co.office_code = atsi.db_office_code
          AND atsi.screening_code = asctl.screening_code(+)
          AND asctl.rate_change_disp_interval_code = ci.interval_code(+);
/

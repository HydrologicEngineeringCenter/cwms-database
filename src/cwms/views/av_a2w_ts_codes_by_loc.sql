insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC', null,
'
/**
 * Displays A2W_TS_CODES_BY_LOC information
 *
 * @since CWMS 2.1
 *
 * @field LOCATION_ID                The...
 * @field DB_OFFICE_ID               The...
 * @field TS_CODE_ELEV               The...
 * @field TS_CODE_PRECIP             The...
 * @field TS_CODE_STAGE              The...
 * @field TS_CODE_INFLOW             The...
 * @field TS_CODE_OUTFLOW            The...
 * @field ts_code_elev_tw         
 * @field ts_code_stage_tw   
 * @field ts_code_rule_curve_elev
 * @field DATE_REFRESHED             The...
 * @field TS_CODE_STOR_FLOOD         The...
 * @field NOTES                      The...
 * @field DISPLAY_FLAG               The...
 * @field NUM_TS_CODES               The...
 * @field TS_CODE_STOR_DROUGHT       The...
 * @field LAKE_SUMMARY_TF            The...
 * @field TS_CODE_SUR_RELEASE        The...
 * @field location_code
 */
');
CREATE OR REPLACE FORCE VIEW "AV_A2W_TS_CODES_BY_LOC" ("LOCATION_ID", "DB_OFFICE_ID", "TS_CODE_ELEV", "TS_CODE_PRECIP", "TS_CODE_STAGE", "TS_CODE_INFLOW", "TS_CODE_OUTFLOW", "TS_CODE_ELEV_TW", "TS_CODE_STAGE_TW", "TS_CODE_RULE_CURVE_ELEV", "DATE_REFRESHED", "TS_CODE_STOR_FLOOD", "NOTES", "DISPLAY_FLAG", "NUM_TS_CODES", "TS_CODE_STOR_DROUGHT", "LAKE_SUMMARY_TF", "TS_CODE_SUR_RELEASE", "LOCATION_CODE") AS 
  select l.location_id,
          l.db_office_id,
          a2w.ts_code_elev,
          a2w.ts_code_precip,
          a2w.ts_code_stage,
          a2w.ts_code_inflow,
          a2w.ts_code_outflow,
          a2w.ts_code_elev_tw,
          a2w.ts_code_stage_tw,
          a2w.ts_code_rule_curve_elev,
          a2w.date_refreshed,
          a2w.ts_code_stor_flood,
          a2w.notes,
          a2w.display_flag,
          a2w.num_ts_codes,
          a2w.ts_code_stor_drought,
          a2w.lake_summary_tf,
          a2w.ts_code_sur_release,
          location_code
     from at_a2w_ts_codes_by_loc a2w join av_loc l using (location_code)
    where l.unit_system = 'SI';
